from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

import numpy as np
import tensorflow as tf
from PIL import Image, ImageFilter, ImageOps


DEFAULT_DATASET_DIR = Path("ml/dataset/pad_ufes_20")
DEFAULT_PLAN_PATH = DEFAULT_DATASET_DIR / "download_plan_balanced.csv"
DEFAULT_IMAGE_DIR = DEFAULT_DATASET_DIR / "selected_images"
DEFAULT_OUTPUT_DIR = DEFAULT_DATASET_DIR / "evaluation_tflite_current"
DEFAULT_MODEL_PATH = Path("ml/output/melanoma_risk_classifier.tflite")
DEFAULT_CONFIG_PATH = Path("ml/output/model_config.json")
APP_CAUTION_THRESHOLD = 0.45
APP_SPECIALIST_THRESHOLD = 0.75


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate the bundled SkinSafe TFLite model on PAD-UFES-20 samples."
    )
    parser.add_argument("--plan", type=Path, default=DEFAULT_PLAN_PATH)
    parser.add_argument("--image-dir", type=Path, default=DEFAULT_IMAGE_DIR)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL_PATH)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG_PATH)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument(
        "--preprocess-mode",
        choices=[
            "resize",
            "center_crop",
            "autocontrast",
            "center_crop_autocontrast",
            "center_crop_sharpen",
        ],
        default=None,
        help="Preprocessing variant to test. Defaults to model_config.json preprocessing_mode.",
    )
    return parser.parse_args()


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


def write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def load_config(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def safe_folder_name(value: str) -> str:
    return value.replace("/", "-").replace("\\", "-")


def image_extension(url: str) -> str:
    suffix = Path(url.split("?", 1)[0]).suffix
    return suffix if suffix else ".jpg"


def image_path_for_row(image_dir: Path, row: dict[str, str]) -> Path:
    return (
        image_dir
        / row["binary_label"]
        / safe_folder_name(row["diagnosis_3"])
        / f"{row['isic_id']}{image_extension(row['full_url'])}"
    )


def preprocess_image(path: Path, width: int, height: int, mode: str) -> np.ndarray:
    with Image.open(path) as image:
        image = ImageOps.exif_transpose(image).convert("RGB")
        if mode in {"center_crop", "center_crop_autocontrast", "center_crop_sharpen"}:
            side = min(image.size)
            left = (image.width - side) // 2
            top = (image.height - side) // 2
            image = image.crop((left, top, left + side, top + side))
        if mode in {"autocontrast", "center_crop_autocontrast"}:
            image = ImageOps.autocontrast(image, cutoff=1)
        if mode == "center_crop_sharpen":
            image = image.filter(ImageFilter.UnsharpMask(radius=1.2, percent=120, threshold=3))
        image = image.resize((width, height), Image.Resampling.BILINEAR)
        array = np.asarray(image, dtype=np.float32)
    return np.expand_dims(array, axis=0)


def compute_metrics(
    rows: list[dict[str, Any]],
    threshold: float,
    prediction_key: str = "melanoma_probability",
) -> dict[str, float | int]:
    true_positive = true_negative = false_positive = false_negative = 0

    for row in rows:
        actual = row["actual_label"] == "melanoma"
        predicted = float(row[prediction_key]) >= threshold
        if actual and predicted:
            true_positive += 1
        elif actual and not predicted:
            false_negative += 1
        elif not actual and predicted:
            false_positive += 1
        else:
            true_negative += 1

    total = len(rows)
    accuracy = (true_positive + true_negative) / total if total else 0.0
    precision = (
        true_positive / (true_positive + false_positive)
        if true_positive + false_positive
        else 0.0
    )
    recall = (
        true_positive / (true_positive + false_negative)
        if true_positive + false_negative
        else 0.0
    )
    specificity = (
        true_negative / (true_negative + false_positive)
        if true_negative + false_positive
        else 0.0
    )
    f1 = (
        2 * precision * recall / (precision + recall)
        if precision + recall
        else 0.0
    )
    beta = 2.0
    f2 = (
        (1 + beta**2) * precision * recall / ((beta**2 * precision) + recall)
        if precision + recall
        else 0.0
    )

    return {
        "threshold": threshold,
        "total": total,
        "true_positive": true_positive,
        "false_negative": false_negative,
        "true_negative": true_negative,
        "false_positive": false_positive,
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "specificity": specificity,
        "f1": f1,
        "f2": f2,
    }


def summarize_by_diagnosis(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        grouped.setdefault(row["diagnosis_3"], []).append(row)

    summary_rows: list[dict[str, Any]] = []
    for diagnosis, diagnosis_rows in sorted(grouped.items()):
        probabilities = [
            float(row["melanoma_probability"])
            for row in diagnosis_rows
        ]
        summary_rows.append(
            {
                "diagnosis_3": diagnosis,
                "count": len(diagnosis_rows),
                "actual_label": diagnosis_rows[0]["actual_label"],
                "average_melanoma_probability": round(float(np.mean(probabilities)), 6),
                "model_positive_count": sum(
                    1 for row in diagnosis_rows if row["model_threshold_positive"]
                ),
                "app_caution_count": sum(
                    1 for row in diagnosis_rows if row["app_caution_or_above"]
                ),
                "app_specialist_count": sum(
                    1 for row in diagnosis_rows if row["app_specialist_or_above"]
                ),
            }
        )
    return summary_rows


def main() -> None:
    args = parse_args()
    config = load_config(args.config)
    image_width, image_height = config.get("image_size", [224, 224])
    model_threshold = float(config.get("threshold", 0.5))
    app_caution_threshold = float(
        config.get("caution_threshold", config.get("threshold", APP_CAUTION_THRESHOLD))
    )
    app_specialist_threshold = float(
        config.get("specialist_threshold", APP_SPECIALIST_THRESHOLD)
    )
    preprocess_mode = args.preprocess_mode or str(config.get("preprocessing_mode", "resize"))

    interpreter = tf.lite.Interpreter(model_path=str(args.model))
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    plan_rows = load_csv(args.plan)
    predictions: list[dict[str, Any]] = []

    for index, row in enumerate(plan_rows, start=1):
        image_path = image_path_for_row(args.image_dir, row)
        if not image_path.exists():
            raise FileNotFoundError(f"Missing planned image: {image_path}")

        input_data = preprocess_image(
            image_path,
            width=image_width,
            height=image_height,
            mode=preprocess_mode,
        )
        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]["index"])
        melanoma_probability = float(np.clip(output.reshape(-1)[0], 0.0, 1.0))

        predictions.append(
            {
                "isic_id": row["isic_id"],
                "actual_label": row["binary_label"],
                "diagnosis_1": row["diagnosis_1"],
                "diagnosis_3": row["diagnosis_3"],
                "anatom_site_1": row["anatom_site_1"],
                "melanoma_probability": melanoma_probability,
                "model_threshold_positive": melanoma_probability >= model_threshold,
                "app_caution_or_above": melanoma_probability >= app_caution_threshold,
                "app_specialist_or_above": melanoma_probability >= app_specialist_threshold,
                "image_path": str(image_path),
            }
        )

        if index % 50 == 0 or index == len(plan_rows):
            print(f"  {index}/{len(plan_rows)} evaluated", flush=True)

    threshold_metrics = compute_metrics(predictions, threshold=model_threshold)
    app_caution_metrics = compute_metrics(predictions, threshold=app_caution_threshold)
    app_specialist_metrics = compute_metrics(
        predictions,
        threshold=app_specialist_threshold,
    )
    diagnosis_summary = summarize_by_diagnosis(predictions)

    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    write_csv(
        output_dir / "predictions.csv",
        predictions,
        [
            "isic_id",
            "actual_label",
            "diagnosis_1",
            "diagnosis_3",
            "anatom_site_1",
            "melanoma_probability",
            "model_threshold_positive",
            "app_caution_or_above",
            "app_specialist_or_above",
            "image_path",
        ],
    )
    write_csv(
        output_dir / "diagnosis_summary.csv",
        diagnosis_summary,
        [
            "diagnosis_3",
            "count",
            "actual_label",
            "average_melanoma_probability",
            "model_positive_count",
            "app_caution_count",
            "app_specialist_count",
        ],
    )

    metrics = {
        "model_path": str(args.model),
        "config_path": str(args.config),
        "model_version": config.get("model_version"),
        "image_size": [image_width, image_height],
        "sample_name": "PAD-UFES-20 selected balanced clinical close-up sample",
        "preprocess_mode": preprocess_mode,
        "sample_images": len(predictions),
        "model_threshold_metrics": threshold_metrics,
        "app_caution_threshold_metrics": app_caution_metrics,
        "app_specialist_threshold_metrics": app_specialist_metrics,
    }
    (output_dir / "metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )

    print(json.dumps(metrics, indent=2), flush=True)
    print(f"Saved predictions to: {output_dir / 'predictions.csv'}", flush=True)
    print(f"Saved diagnosis summary to: {output_dir / 'diagnosis_summary.csv'}", flush=True)


if __name__ == "__main__":
    main()
