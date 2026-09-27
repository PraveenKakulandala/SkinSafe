from __future__ import annotations

import argparse
import csv
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split

sys.path.insert(0, str(Path(__file__).resolve().parent))

from train_model import (
    IMAGE_SIZE,
    SEED,
    build_dataset,
    build_training_callbacks,
    compute_training_class_weights,
    evaluate_threshold_metrics,
    export_tflite,
    prepare_fine_tuning,
    select_validation_threshold,
)


DEFAULT_DATASET_DIR = Path("ml/dataset/pad_ufes_20")
DEFAULT_PLAN_PATH = DEFAULT_DATASET_DIR / "download_plan_balanced.csv"
DEFAULT_IMAGE_DIR = DEFAULT_DATASET_DIR / "selected_images"
DEFAULT_BASE_MODEL_PATH = Path("ml/output/melanoma_risk_classifier.keras")
DEFAULT_OUTPUT_DIR = Path("ml/output_candidate_pad_ufes")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fine-tune the existing SkinSafe melanoma model with the selected "
            "PAD-UFES-20 clinical close-up sample."
        )
    )
    parser.add_argument("--plan", type=Path, default=DEFAULT_PLAN_PATH)
    parser.add_argument("--image-dir", type=Path, default=DEFAULT_IMAGE_DIR)
    parser.add_argument("--base-model", type=Path, default=DEFAULT_BASE_MODEL_PATH)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--fine-tune-at", type=int, default=100)
    parser.add_argument("--learning-rate", type=float, default=3e-6)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--validation-ratio", type=float, default=0.15)
    parser.add_argument("--test-ratio", type=float, default=0.15)
    parser.add_argument(
        "--threshold-beta",
        type=float,
        default=3.0,
        help=(
            "F-beta value used for threshold selection. Higher values prioritize "
            "melanoma recall for screening."
        ),
    )
    parser.add_argument("--export-tflite", action="store_true")
    return parser.parse_args()


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


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


def load_pad_frame(plan_path: Path, image_dir: Path) -> pd.DataFrame:
    rows = []
    for row in load_csv(plan_path):
        image_path = image_path_for_row(image_dir, row)
        if not image_path.exists():
            raise FileNotFoundError(f"Missing PAD image: {image_path}")

        target_label = row["binary_label"]
        rows.append(
            {
                "image_id": row["isic_id"],
                "image_path": str(image_path),
                "target_label": target_label,
                "target_index": 1.0 if target_label == "melanoma" else 0.0,
                "diagnosis_1": row.get("diagnosis_1", ""),
                "diagnosis_3": row.get("diagnosis_3", ""),
                "anatom_site_1": row.get("anatom_site_1", ""),
                "patient_id": row.get("patient_id", ""),
                "lesion_id": row.get("lesion_id", ""),
                "source_dataset": "PAD-UFES-20",
            }
        )

    frame = pd.DataFrame(rows)
    if frame.empty:
        raise ValueError("No PAD-UFES rows were loaded.")
    return frame


def split_frame(
    frame: pd.DataFrame,
    validation_ratio: float,
    test_ratio: float,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    if validation_ratio <= 0 or test_ratio <= 0:
        raise ValueError("validation_ratio and test_ratio must both be greater than 0.")
    if validation_ratio + test_ratio >= 1:
        raise ValueError("validation_ratio + test_ratio must be less than 1.")

    train_val_frame, test_frame = train_test_split(
        frame,
        test_size=test_ratio,
        stratify=frame["target_label"],
        random_state=SEED,
    )
    adjusted_validation_ratio = validation_ratio / (1 - test_ratio)
    train_frame, validation_frame = train_test_split(
        train_val_frame,
        test_size=adjusted_validation_ratio,
        stratify=train_val_frame["target_label"],
        random_state=SEED,
    )
    return (
        train_frame.reset_index(drop=True),
        validation_frame.reset_index(drop=True),
        test_frame.reset_index(drop=True),
    )


def save_pad_outputs(
    output_dir: Path,
    model: tf.keras.Model,
    history: tf.keras.callbacks.History,
    metrics: dict[str, float],
    threshold: float,
    train_frame: pd.DataFrame,
    validation_frame: pd.DataFrame,
    test_frame: pd.DataFrame,
    export_tflite_model: bool,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    model_path = output_dir / "melanoma_risk_classifier.keras"
    model.save(str(model_path))

    labels_path = output_dir / "labels.txt"
    labels_path.write_text("non_melanoma\nmelanoma\n", encoding="utf-8")

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    model_version = f"ham10000-padufes-melanoma-binary-{timestamp}"

    config = {
        "task": "melanoma_binary",
        "class_names": ["non_melanoma", "melanoma"],
        "image_size": list(IMAGE_SIZE),
        "threshold": threshold,
        "model_version": model_version,
        "saved_model_path": str(model_path),
        "labels_path": str(labels_path),
        "training_note": (
            "Base model trained on HAM10000, then fine-tuned on a selected "
            "PAD-UFES-20 clinical close-up sample."
        ),
        "metrics": metrics,
    }

    (output_dir / "model_config.json").write_text(
        json.dumps(config, indent=2),
        encoding="utf-8",
    )
    (output_dir / "training_history.json").write_text(
        json.dumps(history.history, indent=2),
        encoding="utf-8",
    )
    (output_dir / "evaluation_metrics.json").write_text(
        json.dumps(metrics, indent=2),
        encoding="utf-8",
    )

    train_frame.to_csv(output_dir / "train_split.csv", index=False)
    validation_frame.to_csv(output_dir / "validation_split.csv", index=False)
    test_frame.to_csv(output_dir / "test_split.csv", index=False)

    if export_tflite_model:
        tflite_path = export_tflite(model, output_dir)
        print(f"Saved TensorFlow Lite model to: {tflite_path}", flush=True)

    print(f"Saved Keras model to: {model_path}", flush=True)
    print(f"Saved model config to: {output_dir / 'model_config.json'}", flush=True)
    print(f"Saved evaluation metrics to: {output_dir / 'evaluation_metrics.json'}", flush=True)


def main() -> None:
    args = parse_args()
    tf.keras.utils.set_random_seed(SEED)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    frame = load_pad_frame(args.plan, args.image_dir)
    print(f"Loaded {len(frame)} PAD-UFES selected images.", flush=True)
    print(frame["target_label"].value_counts(), flush=True)

    train_frame, validation_frame, test_frame = split_frame(
        frame,
        validation_ratio=args.validation_ratio,
        test_ratio=args.test_ratio,
    )
    print(
        "Split sizes: "
        f"train={len(train_frame)}, validation={len(validation_frame)}, "
        f"test={len(test_frame)}",
        flush=True,
    )

    train_dataset = build_dataset(train_frame, batch_size=args.batch_size, shuffle=True)
    validation_dataset = build_dataset(
        validation_frame,
        batch_size=args.batch_size,
        shuffle=False,
    )
    test_dataset = build_dataset(test_frame, batch_size=args.batch_size, shuffle=False)

    class_weights = compute_training_class_weights(train_frame)
    print(f"Using PAD class weights: {class_weights}", flush=True)

    if not args.base_model.exists():
        raise FileNotFoundError(f"Base model not found: {args.base_model}")

    model = tf.keras.models.load_model(str(args.base_model))
    prepare_fine_tuning(
        model=model,
        fine_tune_at=args.fine_tune_at,
        learning_rate=args.learning_rate,
    )

    history = model.fit(
        train_dataset,
        validation_data=validation_dataset,
        epochs=args.epochs,
        class_weight=class_weights,
        callbacks=build_training_callbacks(args.output_dir, phase_name="pad_ufes"),
    )

    threshold, validation_threshold_metrics = select_validation_threshold(
        model=model,
        validation_dataset=validation_dataset,
        validation_frame=validation_frame,
        beta=args.threshold_beta,
    )
    print(f"Selected PAD validation threshold: {threshold:.3f}", flush=True)

    metrics = {
        key: float(value)
        for key, value in model.evaluate(test_dataset, return_dict=True).items()
    }
    metrics.update(validation_threshold_metrics)
    metrics.update(
        evaluate_threshold_metrics(
            model=model,
            dataset=test_dataset,
            frame=test_frame,
            threshold=threshold,
            prefix="test",
            beta=args.threshold_beta,
        )
    )
    for metric_name, metric_value in metrics.items():
        print(f"{metric_name}: {metric_value:.4f}", flush=True)

    save_pad_outputs(
        output_dir=args.output_dir,
        model=model,
        history=history,
        metrics=metrics,
        threshold=threshold,
        train_frame=train_frame,
        validation_frame=validation_frame,
        test_frame=test_frame,
        export_tflite_model=args.export_tflite,
    )


if __name__ == "__main__":
    main()
