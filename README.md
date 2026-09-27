# SkinSafe

SkinSafe is a Flutter melanoma-screening support app with Firebase authentication, guided image capture, on-device TensorFlow Lite scan review, local image storage, Firestore metadata history, and educational screens.

## Current Product Status

This repository contains the current application, trained models, research documents, and development tools. Store release setup and independent clinical validation remain separate work.

Implemented now:

- Firebase Email/Password sign up, login, reset password, and logout
- onboarding flow and profile shell
- guided scan screen with camera/gallery image selection
- on-device TensorFlow Lite scan review
- local device storage for raw photos and generated lesion illustrations
- Firestore scan metadata save/load
- history, learn, and profile screens
- local HAM10000-trained model exported to TensorFlow Lite
- offline-friendly scan analysis without a running Python server
- emulator support and USB Android phone support
- one-time medical safety disclosure before using the signed-in app
- follow-up planning card on the home dashboard
- ghost-reference follow-up overlay support for previously saved lesions
- latest-vs-previous lesion comparison in History

Still required outside the repo before public store release:

- final app identifiers and regenerated Firebase config if identifiers change
- hosted privacy policy URL and legal pages
- release signing
- optional production API hosting only if future cloud inference is selected
- Play Console / App Store Connect declarations and forms
- medical-grade model validation if you intend to market it as clinical software

## Project Structure

```text
lib/
  app/
  core/
  features/
  services/
  shared/
ml/
  dataset/
  output/
scripts/
test/
```

## Requirements

- Flutter installed and available on `PATH`
- Android emulator or Android phone
- Firebase project already configured for this app
- Python and the packages in `ml/requirements.txt` only when using the optional development API or training tools

## Repository Contents

The repository includes the Flutter source, tests, platform projects, 3D body asset, active TensorFlow Lite and Keras models, model configuration, thesis documents, diagrams, and the [AI agent handover](AI_AGENT_HELP/README.md).

Downloaded training images, local databases, build output, Python runtimes, model checkpoints, credentials, and temporary screenshots are excluded. These files stay on the development machine. After cloning, run `flutter pub get`, then `flutter run -d YOUR_DEVICE_ID`. The bundled model supports normal scan analysis without Python.

The Firebase client configuration is included for this project's existing backend. A separate deployment should use its own Firebase project configuration and deploy the owner-only rules in `firestore.rules`.

## Optional Development AI API

The app now uses the bundled TensorFlow Lite model for normal scan review. The Python API remains useful for model research, comparison testing, and development checks.

Start the optional prediction backend in one terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ai_api.ps1
```

Health check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check_ai_health.ps1
```

Expected response:

```json
{
  "status": "ok"
}
```

## Run On Android Emulator

Start the Flutter app in another terminal:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_flutter_emulator.ps1
```

Or target a specific emulator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_flutter_emulator.ps1 -DeviceId emulator-5554
```

The Android app uses the bundled model by default. If you explicitly switch back to the development API service, the emulator endpoint is:

- `http://10.0.2.2:8000/predict`

## Run On Android Phone Over USB

If your phone is already visible in `flutter devices`, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_flutter_usb.ps1 -DeviceId 073bdad90406
```

That script runs the app directly on the phone. The AI model is bundled in the app, so no Python API or `adb reverse` command is needed for normal scanning.

## Run Tests

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_widget_tests.ps1
```

## Verified Working Flow

The current end-to-end MVP flow is:

1. Create account or sign in
2. Open `Scan`
3. Capture a photo or choose one from gallery
4. Analyze the image with the bundled TensorFlow Lite model
5. Show class, risk, confidence, and recommendation
6. Save the raw photo and generated lesion illustration on the device
7. Save metadata to Firestore
8. View the saved result in `History`

## Local Model

The active model was trained on HAM10000 and fine-tuned using a selected PAD-UFES-20 sample. Its files are:

- [`ml/output/melanoma_risk_classifier.keras`](ml/output/melanoma_risk_classifier.keras)
- [`ml/output/melanoma_risk_classifier.tflite`](ml/output/melanoma_risk_classifier.tflite)

Current configuration:

- model version: `ham10000-padufes-melanoma-binary-20260831T071059Z`
- input size: `224 x 224`
- preprocessing: `center_crop_sharpen`
- caution threshold: `0.45`
- specialist-review threshold: `0.75`

The [recorded selected-sample evaluation](docs/model_test_evidence_20260831.md) reports 49 warnings among 52 melanoma images and 46 false warnings among 260 non-melanoma images. These counts describe that evaluation sample and do not establish accuracy for new patients or independent clinical validation. Training and validation metrics are stored separately in `ml/output/evaluation_metrics.json`.

## VS Code Tasks

The workspace now includes ready-to-run tasks:

- `SkinSafe: Start AI API`
- `SkinSafe: Check AI Health`
- `SkinSafe: Run Flutter Emulator`
- `SkinSafe: Run Flutter USB`
- `SkinSafe: Widget Tests`

Open VS Code Command Palette and use `Tasks: Run Task`.

## Publish Notes

Uploading this repository backs up the project. Public app-store submission still requires the release setup listed above, and model outputs remain screening-support guidance.

For the remaining external submission work, use:

- [docs/PUBLISH_CHECKLIST.md](docs/PUBLISH_CHECKLIST.md)
