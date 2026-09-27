from __future__ import annotations

import base64
import io
import json
from pathlib import Path

import numpy as np
from scipy import ndimage
import tensorflow as tf
import uvicorn
from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image


ROOT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = ROOT_DIR / "output"
MODEL_PATH = OUTPUT_DIR / "melanoma_risk_classifier.keras"
CONFIG_PATH = OUTPUT_DIR / "model_config.json"


class SkinSafePredictor:
    def __init__(self, model_path: Path, config_path: Path) -> None:
        if not model_path.exists():
            raise FileNotFoundError(f"Model file not found: {model_path}")
        if not config_path.exists():
            raise FileNotFoundError(f"Config file not found: {config_path}")

        self.model = tf.keras.models.load_model(str(model_path))
        self.config = json.loads(config_path.read_text(encoding="utf-8"))
        self.image_size = tuple(self.config.get("image_size", [224, 224]))
        self.threshold = float(self.config.get("threshold", 0.5))
        self.model_version = self.config.get("model_version", "unknown")

    def predict_bytes(self, image_bytes: bytes) -> dict[str, object]:
        source_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        illustration_base64, lesion_coverage_percent = (
            self._create_lesion_illustration(source_image)
        )

        model_image = source_image.resize(self.image_size)
        image_array = np.asarray(model_image, dtype=np.float32)
        image_array = np.expand_dims(image_array, axis=0)

        prediction = float(self.model.predict(image_array, verbose=0)[0][0])
        melanoma_probability = max(0.0, min(1.0, prediction))
        non_melanoma_probability = 1.0 - melanoma_probability

        predicted_class = (
            "Melanoma pattern"
            if melanoma_probability >= self.threshold
            else "Non-melanoma pattern"
        )
        confidence = max(melanoma_probability, non_melanoma_probability)
        status, summary, recommendation = self._build_patient_message(
            melanoma_probability
        )

        return {
            "predicted_class": predicted_class,
            "melanoma_probability": melanoma_probability,
            "confidence": confidence,
            "status": status,
            "summary": summary,
            "recommendation": recommendation,
            "model_version": self.model_version,
            "illustration_base64": illustration_base64,
            "illustration_mime_type": "image/png",
            "illustration_filename": "lesion_illustration.png",
            "lesion_coverage_percent": lesion_coverage_percent,
            "visualization_summary": (
                "A generated lesion-shape illustration was created from the scan "
                "and can be saved instead of the raw source photo."
            ),
            "probabilities": {
                "melanoma": melanoma_probability,
                "non_melanoma": non_melanoma_probability,
            },
        }

    def _create_lesion_illustration(
        self,
        image: Image.Image,
    ) -> tuple[str, float]:
        working = image.copy()
        working.thumbnail((512, 512))

        rgb = np.asarray(working, dtype=np.float32) / 255.0
        grayscale = (
            0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]
        )
        skin_reference = float(np.percentile(grayscale, 72))
        darkness = np.clip(
            (skin_reference - grayscale) / max(skin_reference, 1e-3),
            0.0,
            1.0,
        )
        redness = np.clip(
            rgb[..., 0] - ((rgb[..., 1] + rgb[..., 2]) / 2.0),
            0.0,
            1.0,
        )
        lesion_score = 0.76 * darkness + 0.24 * redness

        candidate_masks: list[np.ndarray] = []
        for percentile in (90, 87, 84, 81, 78, 75):
            threshold = float(np.percentile(lesion_score, percentile))
            mask = lesion_score >= threshold
            mask = ndimage.binary_opening(mask, iterations=1)
            mask = ndimage.binary_closing(mask, iterations=2)
            mask = ndimage.binary_fill_holes(mask)
            mask = self._largest_component(mask)
            if np.any(mask):
                candidate_masks.append(mask)

        if candidate_masks:
            mask = min(
                candidate_masks,
                key=lambda current_mask: abs(current_mask.mean() - 0.18),
            )
        else:
            mask = lesion_score >= float(np.percentile(lesion_score, 84))

        mask = ndimage.binary_opening(mask, iterations=1)
        mask = ndimage.binary_closing(mask, iterations=2)
        mask = ndimage.binary_fill_holes(mask)
        mask = self._largest_component(mask)

        lesion_coverage_percent = float(mask.mean() * 100.0)

        background = np.zeros((*mask.shape, 3), dtype=np.uint8)
        background[:, :] = np.array([248, 243, 238], dtype=np.uint8)

        fill_dark = np.array([89, 43, 31], dtype=np.float32)
        fill_light = np.array([191, 111, 83], dtype=np.float32)
        fill_mix = np.clip(0.35 + 0.65 * lesion_score, 0.0, 1.0)
        lesion_fill = (
            fill_light[None, None, :] * (1.0 - fill_mix[..., None])
            + fill_dark[None, None, :] * fill_mix[..., None]
        ).astype(np.uint8)

        illustration = background.copy()
        illustration[mask] = lesion_fill[mask]

        contour = np.logical_xor(mask, ndimage.binary_erosion(mask, iterations=1))
        illustration[contour] = np.array([30, 109, 216], dtype=np.uint8)

        inner_shadow = ndimage.binary_erosion(mask, iterations=4)
        illustration[inner_shadow] = (
            0.78 * illustration[inner_shadow]
            + 0.22 * np.array([61, 27, 18], dtype=np.float32)
        ).astype(np.uint8)

        image_output = Image.fromarray(illustration, mode="RGB")
        buffer = io.BytesIO()
        image_output.save(buffer, format="PNG")
        encoded = base64.b64encode(buffer.getvalue()).decode("utf-8")
        return encoded, lesion_coverage_percent

    def _largest_component(self, mask: np.ndarray) -> np.ndarray:
        labels, total = ndimage.label(mask)
        if total == 0:
            return mask

        component_sizes = ndimage.sum(
            mask,
            labels,
            index=np.arange(1, total + 1),
        )
        largest_component = int(np.argmax(component_sizes)) + 1
        return labels == largest_component

    def _build_patient_message(
        self,
        melanoma_probability: float,
    ) -> tuple[str, str, str]:
        if melanoma_probability >= 0.75:
            return (
                "Specialist review recommended",
                "The model detected a strong melanoma-like pattern in this image.",
                "Please arrange dermatologist review as soon as possible. This app result supports decision-making but is not a medical diagnosis.",
            )
        if melanoma_probability >= 0.4:
            return (
                "Caution advised",
                "The model found features that deserve closer review.",
                "Consider repeating the scan under clear lighting and seek dermatologist review, especially if the lesion is changing in shape, color, border, or symptoms.",
            )
        return (
            "Low melanoma risk",
            "The model found a stronger match with non-melanoma examples than melanoma examples.",
            "Continue monitoring the lesion and repeat the scan if the area changes over time. Seek clinician review if you remain concerned.",
        )


app = FastAPI(title="SkinSafe Prediction API")


@app.on_event("startup")
async def startup_event() -> None:
    app.state.predictor = SkinSafePredictor(MODEL_PATH, CONFIG_PATH)


@app.get("/health")
async def health() -> dict[str, object]:
    predictor: SkinSafePredictor | None = getattr(app.state, "predictor", None)
    if predictor is None:
        raise HTTPException(status_code=503, detail="Predictor is not loaded.")

    return {
        "status": "ok",
        "model_version": predictor.model_version,
        "image_size": predictor.image_size,
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)) -> dict[str, object]:
    predictor: SkinSafePredictor | None = getattr(app.state, "predictor", None)
    if predictor is None:
        raise HTTPException(status_code=503, detail="Predictor is not loaded.")

    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    try:
        return predictor.predict_bytes(contents)
    except Exception as error:  # noqa: BLE001
        raise HTTPException(
            status_code=400,
            detail=f"Prediction failed: {error}",
        ) from error


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
