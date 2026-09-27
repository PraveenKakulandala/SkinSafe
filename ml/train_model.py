from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.utils.class_weight import compute_class_weight


ROOT_DIR = Path(__file__).resolve().parent
DEFAULT_DATASET_ROOT = ROOT_DIR / "dataset" / "ham10000"
DEFAULT_OUTPUT_DIR = ROOT_DIR / "output"
IMAGE_SIZE = (224, 224)
SEED = 42


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Train a melanoma-risk classifier from HAM10000 metadata.",
    )
    parser.add_argument(
        "--dataset-root",
        type=Path,
        default=DEFAULT_DATASET_ROOT,
        help="Folder that contains HAM10000 metadata and image folders.",
    )
    parser.add_argument(
        "--metadata",
        type=Path,
        default=None,
        help="Optional explicit path to HAM10000_metadata.csv.",
    )
    parser.add_argument(
        "--images-dir",
        type=Path,
        action="append",
        default=[],
        help="Optional image directories. Repeat the flag for multiple folders.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Folder where the trained model and metadata will be saved.",
    )
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument(
        "--fine-tune-epochs",
        type=int,
        default=0,
        help=(
            "Optional second training stage. Unfreezes the top MobileNetV2 "
            "layers and continues training with a smaller learning rate."
        ),
    )
    parser.add_argument(
        "--fine-tune-at",
        type=int,
        default=120,
        help="MobileNetV2 layer index to start fine-tuning from.",
    )
    parser.add_argument(
        "--fine-tune-learning-rate",
        type=float,
        default=1e-5,
        help="Learning rate used during optional fine-tuning.",
    )
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--learning-rate", type=float, default=1e-3)
    parser.add_argument("--validation-ratio", type=float, default=0.15)
    parser.add_argument("--test-ratio", type=float, default=0.15)
    parser.add_argument(
        "--export-tflite",
        action="store_true",
        help="Also export a TensorFlow Lite model.",
    )
    parser.add_argument(
        "--resume-model",
        type=Path,
        default=None,
        help=(
            "Optional existing Keras model to continue training from. "
            "Use this when improving the current app model instead of "
            "starting from scratch."
        ),
    )
    parser.add_argument(
        "--skip-head-training",
        action="store_true",
        help=(
            "Skip the frozen-backbone head training stage. This is useful "
            "with --resume-model when you only want extra fine-tuning."
        ),
    )
    parser.add_argument(
        "--threshold-beta",
        type=float,
        default=2.0,
        help=(
            "F-beta value used when selecting the operating threshold. "
            "Values above 1 prioritize melanoma recall."
        ),
    )
    return parser.parse_args()


def resolve_metadata_path(dataset_root: Path, metadata_override: Path | None) -> Path:
    if metadata_override is not None:
        if metadata_override.exists():
            return metadata_override
        raise FileNotFoundError(f"Metadata file not found: {metadata_override}")

    candidates = [
        dataset_root / "HAM10000_metadata.csv",
        dataset_root / "HAM10000_metadata.tab",
        dataset_root / "metadata" / "HAM10000_metadata.csv",
        dataset_root / "metadata" / "HAM10000_metadata.tab",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        "HAM10000 metadata was not found. "
        "Place it under ml/dataset/ham10000/ or pass --metadata."
    )


def resolve_image_directories(
    dataset_root: Path,
    image_overrides: list[Path],
) -> list[Path]:
    if image_overrides:
        image_dirs = [path for path in image_overrides if path.exists()]
        if image_dirs:
            return image_dirs
        raise FileNotFoundError("None of the supplied --images-dir paths exist.")

    candidates = [
        dataset_root / "images",
        dataset_root / "HAM10000_images",
        dataset_root / "HAM10000_images_part_1",
        dataset_root / "HAM10000_images_part_2",
    ]
    image_dirs = [path for path in candidates if path.exists()]
    if image_dirs:
        return image_dirs

    raise FileNotFoundError(
        "No HAM10000 image directories were found. "
        "Create ml/dataset/ham10000/images or pass --images-dir."
    )


def build_image_lookup(image_directories: list[Path]) -> dict[str, Path]:
    image_lookup: dict[str, Path] = {}
    for directory in image_directories:
        for image_path in directory.glob("*.jpg"):
            image_lookup[image_path.stem] = image_path
        for image_path in directory.glob("*.jpeg"):
            image_lookup[image_path.stem] = image_path
    return image_lookup


def load_training_frame(
    metadata_path: Path,
    image_directories: list[Path],
) -> pd.DataFrame:
    separator = "\t" if metadata_path.suffix.lower() == ".tab" else None
    frame = pd.read_csv(
        metadata_path,
        sep=separator,
        engine="python" if separator is None else None,
    )
    required_columns = {"image_id", "dx"}
    missing_columns = required_columns.difference(frame.columns)
    if missing_columns:
        raise ValueError(
            f"Metadata file is missing required columns: {sorted(missing_columns)}"
        )

    image_lookup = build_image_lookup(image_directories)
    frame = frame.copy()
    frame["image_path"] = frame["image_id"].map(
        lambda image_id: str(image_lookup.get(image_id, ""))
    )
    frame = frame[frame["image_path"] != ""].reset_index(drop=True)

    if frame.empty:
        raise ValueError("No metadata rows could be matched to image files.")

    frame["target_label"] = np.where(frame["dx"] == "mel", "melanoma", "non_melanoma")
    frame["target_index"] = np.where(frame["dx"] == "mel", 1, 0).astype("float32")
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


def build_dataset(
    frame: pd.DataFrame,
    batch_size: int,
    shuffle: bool,
) -> tf.data.Dataset:
    paths = frame["image_path"].tolist()
    labels = frame["target_index"].astype("float32").tolist()

    dataset = tf.data.Dataset.from_tensor_slices((paths, labels))
    if shuffle:
        dataset = dataset.shuffle(buffer_size=len(frame), seed=SEED)

    def load_item(path: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
        image_bytes = tf.io.read_file(path)
        image = tf.io.decode_jpeg(image_bytes, channels=3)
        image = tf.image.resize(image, IMAGE_SIZE)
        image = tf.cast(image, tf.float32)
        label = tf.reshape(tf.cast(label, tf.float32), (1,))
        return image, label

    dataset = dataset.map(load_item, num_parallel_calls=tf.data.AUTOTUNE)
    dataset = dataset.batch(batch_size).prefetch(tf.data.AUTOTUNE)
    return dataset


def create_model(learning_rate: float) -> tf.keras.Model:
    augmentation = tf.keras.Sequential(
        [
            tf.keras.layers.RandomFlip("horizontal"),
            tf.keras.layers.RandomRotation(0.05),
            tf.keras.layers.RandomZoom(0.08),
            tf.keras.layers.RandomContrast(0.1),
            tf.keras.layers.RandomTranslation(0.04, 0.04),
        ],
        name="augmentation",
    )

    backbone = tf.keras.applications.MobileNetV2(
        input_shape=IMAGE_SIZE + (3,),
        include_top=False,
        weights="imagenet",
        name="mobilenetv2_backbone",
    )
    backbone.trainable = False

    inputs = tf.keras.Input(shape=IMAGE_SIZE + (3,), name="scan_image")
    x = augmentation(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = backbone(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.35)(x)
    x = tf.keras.layers.Dense(
        128,
        activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(1e-4),
    )(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(0.25)(x)
    outputs = tf.keras.layers.Dense(
        1,
        activation="sigmoid",
        name="melanoma_probability",
    )(x)

    model = tf.keras.Model(inputs=inputs, outputs=outputs, name="skinsafe_melanoma")
    compile_model(model, learning_rate)
    return model


def compile_model(model: tf.keras.Model, learning_rate: float) -> None:
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss="binary_crossentropy",
        metrics=[
            tf.keras.metrics.BinaryAccuracy(name="accuracy"),
            tf.keras.metrics.AUC(name="auc"),
            tf.keras.metrics.Precision(name="precision"),
            tf.keras.metrics.Recall(name="recall"),
        ],
    )


def prepare_fine_tuning(
    model: tf.keras.Model,
    fine_tune_at: int,
    learning_rate: float,
) -> None:
    backbone = model.get_layer("mobilenetv2_backbone")
    backbone.trainable = True

    for layer in backbone.layers[:fine_tune_at]:
        layer.trainable = False

    # Batch normalization statistics are kept fixed for stable transfer learning.
    for layer in backbone.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False

    compile_model(model, learning_rate)


def build_training_callbacks(
    output_dir: Path,
    phase_name: str,
) -> list[tf.keras.callbacks.Callback]:
    checkpoint_name = (
        "best_checkpoint.keras"
        if phase_name == "head"
        else f"best_checkpoint_{phase_name}.keras"
    )
    return [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_auc",
            mode="max",
            patience=3,
            restore_best_weights=True,
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(output_dir / checkpoint_name),
            monitor="val_auc",
            mode="max",
            save_best_only=True,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_auc",
            mode="max",
            factor=0.5,
            patience=2,
            min_lr=1e-6,
        ),
    ]


def compute_training_class_weights(frame: pd.DataFrame) -> dict[int, float]:
    labels = frame["target_index"].astype("int32").to_numpy()
    classes = np.array([0, 1], dtype=np.int32)
    weights = compute_class_weight(
        class_weight="balanced",
        classes=classes,
        y=labels,
    )
    return {int(class_id): float(weight) for class_id, weight in zip(classes, weights)}


def select_validation_threshold(
    model: tf.keras.Model,
    validation_dataset: tf.data.Dataset,
    validation_frame: pd.DataFrame,
    beta: float,
) -> tuple[float, dict[str, float]]:
    probabilities = model.predict(validation_dataset, verbose=0).reshape(-1)
    labels = validation_frame["target_index"].astype("int32").to_numpy()

    best_threshold = 0.5
    best_score = -1.0
    best_metrics: dict[str, float] = {}

    for threshold in np.linspace(0.05, 0.95, 181):
        metrics = compute_threshold_metrics(
            labels=labels,
            probabilities=probabilities,
            threshold=float(threshold),
            prefix="validation",
            beta=beta,
        )
        score = metrics["validation_threshold_f_beta"]
        if score > best_score:
            best_score = score
            best_threshold = float(threshold)
            best_metrics = metrics

    best_metrics["validation_threshold_beta"] = float(beta)
    return best_threshold, best_metrics


def evaluate_threshold_metrics(
    model: tf.keras.Model,
    dataset: tf.data.Dataset,
    frame: pd.DataFrame,
    threshold: float,
    prefix: str,
    beta: float,
) -> dict[str, float]:
    probabilities = model.predict(dataset, verbose=0).reshape(-1)
    labels = frame["target_index"].astype("int32").to_numpy()
    return compute_threshold_metrics(
        labels=labels,
        probabilities=probabilities,
        threshold=threshold,
        prefix=prefix,
        beta=beta,
    )


def compute_threshold_metrics(
    labels: np.ndarray,
    probabilities: np.ndarray,
    threshold: float,
    prefix: str,
    beta: float,
) -> dict[str, float]:
    predictions = probabilities >= threshold
    positives = labels == 1
    negatives = labels == 0

    true_positive = float(np.logical_and(predictions, positives).sum())
    false_positive = float(np.logical_and(predictions, negatives).sum())
    true_negative = float(np.logical_and(~predictions, negatives).sum())
    false_negative = float(np.logical_and(~predictions, positives).sum())

    precision = true_positive / max(true_positive + false_positive, 1.0)
    recall = true_positive / max(true_positive + false_negative, 1.0)
    specificity = true_negative / max(true_negative + false_positive, 1.0)
    accuracy = (true_positive + true_negative) / max(float(len(labels)), 1.0)
    f_beta = _compute_f_beta(precision=precision, recall=recall, beta=beta)
    f2 = _compute_f_beta(precision=precision, recall=recall, beta=2.0)

    return {
        f"{prefix}_threshold": float(threshold),
        f"{prefix}_threshold_precision": float(precision),
        f"{prefix}_threshold_recall": float(recall),
        f"{prefix}_threshold_specificity": float(specificity),
        f"{prefix}_threshold_accuracy": float(accuracy),
        f"{prefix}_threshold_f_beta": float(f_beta),
        f"{prefix}_threshold_f2": float(f2),
    }


def _compute_f_beta(precision: float, recall: float, beta: float) -> float:
    return (
        (1 + beta**2)
        * precision
        * recall
        / max((beta**2 * precision) + recall, 1e-7)
    )


def export_tflite(model: tf.keras.Model, output_dir: Path) -> Path:
    tflite_path = output_dir / "melanoma_risk_classifier.tflite"
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    tflite_path.write_bytes(tflite_model)
    return tflite_path


def save_outputs(
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
    model_version = f"ham10000-melanoma-binary-{timestamp}"

    config = {
        "task": "melanoma_binary",
        "class_names": ["non_melanoma", "melanoma"],
        "image_size": list(IMAGE_SIZE),
        "threshold": threshold,
        "model_version": model_version,
        "saved_model_path": str(model_path),
        "labels_path": str(labels_path),
        "metrics": metrics,
    }

    config_path = output_dir / "model_config.json"
    config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")

    history_path = output_dir / "training_history.json"
    history_path.write_text(json.dumps(history.history, indent=2), encoding="utf-8")

    metrics_path = output_dir / "evaluation_metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    train_frame.to_csv(output_dir / "train_split.csv", index=False)
    validation_frame.to_csv(output_dir / "validation_split.csv", index=False)
    test_frame.to_csv(output_dir / "test_split.csv", index=False)

    if export_tflite_model:
        tflite_path = export_tflite(model, output_dir)
        print(f"Saved TensorFlow Lite model to: {tflite_path}")

    print(f"Saved Keras model to: {model_path}")
    print(f"Saved model config to: {config_path}")
    print(f"Saved evaluation metrics to: {metrics_path}")


def main() -> None:
    args = parse_args()
    tf.keras.utils.set_random_seed(SEED)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    metadata_path = resolve_metadata_path(args.dataset_root, args.metadata)
    image_directories = resolve_image_directories(args.dataset_root, args.images_dir)
    frame = load_training_frame(metadata_path, image_directories)

    print(f"Matched {len(frame)} images from metadata.")
    print(frame["target_label"].value_counts())

    train_frame, validation_frame, test_frame = split_frame(
        frame,
        validation_ratio=args.validation_ratio,
        test_ratio=args.test_ratio,
    )

    train_dataset = build_dataset(
        train_frame,
        batch_size=args.batch_size,
        shuffle=True,
    )
    validation_dataset = build_dataset(
        validation_frame,
        batch_size=args.batch_size,
        shuffle=False,
    )
    test_dataset = build_dataset(
        test_frame,
        batch_size=args.batch_size,
        shuffle=False,
    )

    class_weights = compute_training_class_weights(train_frame)
    print(f"Using class weights: {class_weights}")

    if args.resume_model is not None:
        if not args.resume_model.exists():
            raise FileNotFoundError(f"Resume model not found: {args.resume_model}")
        print(f"Loading existing model for continued training: {args.resume_model}")
        model = tf.keras.models.load_model(str(args.resume_model))
        compile_model(model, args.learning_rate)
    else:
        model = create_model(args.learning_rate)

    combined_history: dict[str, list[float]] = {}
    history = None

    if not args.skip_head_training and args.epochs > 0:
        history = model.fit(
            train_dataset,
            validation_data=validation_dataset,
            epochs=args.epochs,
            class_weight=class_weights,
            callbacks=build_training_callbacks(args.output_dir, phase_name="head"),
        )
        combined_history.update(
            {
                f"head_{key}": value
                for key, value in history.history.items()
            }
        )
    else:
        print("Skipping frozen-backbone head training stage.")

    if args.fine_tune_epochs > 0:
        print(
            "Starting fine-tuning stage "
            f"for {args.fine_tune_epochs} epoch(s) from layer {args.fine_tune_at}."
        )
        prepare_fine_tuning(
            model=model,
            fine_tune_at=args.fine_tune_at,
            learning_rate=args.fine_tune_learning_rate,
        )
        fine_tune_history = model.fit(
            train_dataset,
            validation_data=validation_dataset,
            epochs=args.fine_tune_epochs,
            class_weight=class_weights,
            callbacks=build_training_callbacks(
                args.output_dir,
                phase_name="fine_tune",
            ),
        )
        combined_history.update(
            {
                f"fine_tune_{key}": value
                for key, value in fine_tune_history.history.items()
            }
        )

    threshold, validation_threshold_metrics = select_validation_threshold(
        model=model,
        validation_dataset=validation_dataset,
        validation_frame=validation_frame,
        beta=args.threshold_beta,
    )
    print(f"Selected validation threshold: {threshold:.3f}")

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
        print(f"{metric_name}: {metric_value:.4f}")

    if history is None:
        history = tf.keras.callbacks.History()
    history.history = combined_history
    save_outputs(
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
