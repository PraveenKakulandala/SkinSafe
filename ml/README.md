# SkinSafe ML Pipeline

This folder now contains the next real step of the project:

- Train a melanoma-risk classifier from the HAM10000 dataset metadata
- Export a Keras model
- Export a TensorFlow Lite model for the Flutter app
- Optionally run a local prediction API for development comparison

## What this version is designed for

This implementation is focused on a **binary melanoma-risk workflow**:

- `mel` -> `melanoma`
- every other HAM10000 diagnosis -> `non_melanoma`

That matches your current app goal better than a 7-class UI.

## Important limitation

HAM10000 and ISIC 2018 mainly contain **dermoscopic images**, not ordinary phone-camera photos.

So this pipeline is valid as a research workflow, but you should describe results carefully in the app:

- good: `Low melanoma risk`, `Caution advised`, `Specialist review recommended`
- avoid: `You have cancer`

## Expected dataset structure

Place the dataset under:

```text
ml/
  dataset/
    ham10000/
      HAM10000_metadata.tab
      HAM10000_images_part_1/
      HAM10000_images_part_2/
```

You can also use:

```text
ml/
  dataset/
    ham10000/
      HAM10000_metadata.tab
      images/
```

## Install dependencies

```bash
.\.python\python311\python.exe -m pip install -r ml/requirements.txt
```

## Train the model

Basic command:

```bash
.\.python\python311\python.exe ml/train_model.py --export-tflite
```

Optional custom paths:

```bash
.\.python\python311\python.exe ml/train_model.py ^
  --dataset-root ml/dataset/ham10000 ^
  --output-dir ml/output ^
  --epochs 8 ^
  --fine-tune-epochs 4 ^
  --fine-tune-at 120 ^
  --batch-size 32 ^
  --export-tflite
```

The training script uses:

- MobileNetV2 transfer learning
- class weights for the imbalanced melanoma/non-melanoma classes
- validation AUC checkpointing
- optional fine-tuning of the upper MobileNetV2 layers
- validation-based threshold selection using F2 score to give recall more weight

## Training outputs

After training, these files are created in `ml/output/`:

- `melanoma_risk_classifier.keras`
- `melanoma_risk_classifier.tflite` if `--export-tflite` is used
- `labels.txt`
- `model_config.json`
- `evaluation_metrics.json`
- `training_history.json`
- `train_split.csv`
- `validation_split.csv`
- `test_split.csv`

## Current exported model

The active app model is under `ml/output/`.

Current evaluation snapshot:

- model version: `ham10000-padufes-melanoma-binary-20260831T071059Z`
- base training: HAM10000 dermoscopic images
- adaptation training: selected PAD-UFES-20 clinical close-up images
- held-out PAD split accuracy: `0.809`
- held-out PAD split AUC: `0.926`
- held-out PAD split recall: `0.875`
- held-out PAD split precision: `0.467`
- active app preprocessing: `center_crop_sharpen`
- active app caution threshold: `0.450`

Current PAD-UFES selected-sample TFLite check:

- sample size: `312`
- melanoma correctly warned at app threshold: `49 / 52`
- melanoma missed at app threshold: `3 / 52`
- non-melanoma false warnings at app threshold: `46 / 260`
- non-melanoma correctly treated as lower risk: `214 / 260`
- selected-sample accuracy: `0.843`
- selected-sample recall: `0.942`
- selected-sample precision: `0.516`

The TensorFlow Lite model uses RGB `0-255` input after the same app-side
orientation correction, center crop, mild sharpening, and resize flow.

## Run the local prediction API

```bash
.\.python\python311\python.exe ml/predict_api.py
```

Default API address:

- local PC: `http://127.0.0.1:8000`
- Android emulator from Flutter: `http://10.0.2.2:8000`
- Android phone over USB after `adb reverse`: `http://127.0.0.1:8000`

### Health check

```bash
curl http://127.0.0.1:8000/health
```

### Predict from an image

```bash
curl -X POST http://127.0.0.1:8000/predict -F "file=@sample.jpg"
```

## Flutter integration

The Flutter app uses `ml/output/melanoma_risk_classifier.tflite` and
`ml/output/model_config.json` as bundled assets. Normal scanning does not need
the Python API, internet access, Firebase Storage, or `adb reverse`.

App flow:

1. Capture or pick image
2. Run on-device TFLite prediction
3. Show melanoma-risk result
4. Save raw photo and generated illustration locally on the device
5. Save result metadata and local paths to Firestore

## Recommended next improvement

After this binary version works well, the next upgrade path is:

1. expand the clinical-photo validation set
2. add artifact/hair and ruler/tattoo rejection checks
3. evaluate on a held-out set carefully
4. decide whether to move to 7-class ISIC diagnosis
5. improve calibration and threshold reporting for patient-friendly results

## References

Use these references in your document:

1. P. Tschandl, C. Rosendahl, and H. Kittler, "The HAM10000 dataset, a large collection of multi-source dermatoscopic images of common pigmented skin lesions," *Scientific Data*, vol. 5, no. 1, p. 180161, 2018.
2. N. C. F. Codella et al., "Skin Lesion Analysis Toward Melanoma Detection: A Challenge at the 2017 International Symposium on Biomedical Imaging (ISBI)," *IEEE ISBI*, pp. 168-172, 2018.
3. A. Esteva et al., "Dermatologist-level classification of skin cancer with deep neural networks," *Nature*, vol. 542, no. 7639, pp. 115-118, 2017.
