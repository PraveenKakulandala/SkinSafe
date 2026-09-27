# AI Agent Handover README - SkinSafe Melanoma Mobile Application

Created for transferring the project context to another GPT/Codex account.

Workspace root:

```text
E:\Melanoma skin cancer
```

Current handover date:

```text
2026-09-22
```

## 1. Project Identity

Project name:

```text
SkinSafe
```

Academic project title:

```text
Melanoma Skin Cancer Detection and Prevention Mobile Application Using Machine Learning
```

Student:

```text
K. L. D. P. P. Kakulandala
Student ID: 28510
Supervisor: Dr. Rasika Ranweera
```

Project purpose:

```text
SkinSafe is a Flutter mobile application that supports melanoma skin cancer screening awareness, lesion photo review, patient follow-up, scan history, prevention education, and safe result communication.
```

Important positioning:

```text
This app must be described as screening support and prevention support.
Do not describe it as a confirmed cancer diagnosis system.
The app should guide users toward follow-up or dermatologist review when needed.
```

## 2. Very Important User Preferences

Keep these rules when continuing the project:

- The user often speaks Sinhala/English in chat, but the codebase and generated project files should stay in English.
- Do not add Sinhala text to Dart code, comments, generated documentation, app UI labels, or README files unless the user explicitly asks for Sinhala content.
- The user wants the app to be publishable and polished, not just a rough prototype.
- Be careful with medical wording. Do not write "you have cancer" in the app.
- Use patient-friendly guidance such as "low risk", "monitor closely", "caution advised", and "specialist review recommended".
- If an AI result is high risk, the app should advise medical review instead of asking the patient to wait for another app scan.
- Doctor directory and booking actions are not needed for now.
- Preserve user app data during Flutter run/install whenever possible. Do not clear emulator/app data unless the user explicitly asks.

## 3. Main Decisions From Our Discussions

### App Flow

The main bottom navigation should remain:

```text
Home
Scan
History
Learn
Profile
```

Inside those areas, the project was conceptually separated into smaller pages/components:

```text
Home:
HomeDashboardPage
ReminderDetailsPage
QuickActionsPage

Scan:
ScanLandingPage
PatientSelectPage
PatientDetailsPage
BodyAreaSelectPage
LesionSpotDetailsPage
QuestionnairePage
PhotoCapturePage
CaptureGuidePage
ScanReviewPage
ScanProcessingPage
ScanResultPage

History:
HistoryPatientPage
BodyAreaHistoryPage
LesionHistoryPage
ScanVisitDetailsPage
ComparisonPage

Learn:
LearnHomePage
ABCDEGuidePage
MelanomaStagesPage
PreventionTipsPage
FAQPage

Profile:
ProfileOverviewPage
EditProfilePage
NotificationSettingsPage
PrivacySettingsPage
LogoutConfirmPage
```

The actual app still has a main integrated frontend file:

```text
lib/app/skinsafe_frontend.dart
```

Feature folders also exist for future modularization:

```text
lib/features/auth
lib/features/dashboard
lib/features/history
lib/features/learn
lib/features/profile
lib/features/scan
lib/services
lib/shared
```

### Scan Flow

The preferred scan flow is:

```text
1. Select or enter patient details
2. Select body area and lesion spot
3. Answer questionnaire/risk-context questions
4. Capture or choose a lesion image
5. Run scan
6. Show processing animation
7. Show result guidance
8. Offer reminder/follow-up action
9. Save to history
```

The user specifically wanted the scan flow split into separate steps instead of one long confusing screen.

### Result Guidance Rules

The result page should use action categories:

| Result type | App action |
| --- | --- |
| Retake recommended | Ask the user to take a clearer photo immediately. |
| Low risk | Save as a first baseline scan and optionally use routine monthly self-check reminders. |
| Monitor closely / uncertain | Suggest saving and re-scanning the same mole in 7 to 14 days. |
| Caution advised | Advise doctor/dermatologist review and allow a shorter follow-up reminder. |
| Specialist review recommended | Show urgent warning: do not wait for app re-scan; arrange dermatologist review. |

Low-risk results should avoid showing unnecessary lesion-shape visual output if it confuses users.

### Reminder Decision

For uncertain or monitor-closely lesions, the chosen reminder window is:

```text
7 to 14 days
```

Do not use a family member phone number for sending sensitive lesion details for now. We discussed it and decided not to add that because privacy and consent risks are high.

### History Flow

The user wanted History to be simple:

```text
1. First show patient names only.
2. After selecting a patient, show body areas that contain saved moles/lesions.
3. After selecting a body area, open a new page with lesion details/timeline.
```

History also has or should support two views:

```text
Normal view:
Patient -> body area -> lesion timeline/details

Full visual detail:
Human body map with lesion markers; tapping a marker opens lesion details.
```

### Body Area Selection

The scan page should support body-area selection by:

```text
1. Dropdown/list selection
2. Visual body map / 3D body reference
```

A 3D mannequin asset exists:

```text
assets/models/medical_mannequin.glb
```

The current 3D/visual body map is functional but can be improved. The user wanted it more realistic and smoother.

### UI Direction

The user asked for a more beautiful, polished UI inspired by premium mobile design and liquid-glass navigation.

Final UI direction chosen:

```text
Medical blue-green / teal theme
Optional dark mode
Rounded cards
Clear medical spacing
Simplified patient flow
Liquid-glass style bottom navigation
Avoid unnecessary scan/result clutter
```

Avoid pink/purple default themes unless the user asks.

### Learn / Prevention / UV

The Learn section should focus on:

```text
Prevention tips
ABCDE guide
Melanoma stages
FAQ
Current UV guidance
```

UV feature direction:

```text
Show current UV level only.
Use color status such as green/yellow/red.
Use it as prevention awareness, not as a certified weather service.
```

### Ethical Communication Research

Supervisor discussion topic:

```text
How doctors communicate possible cancer warnings to patients and what factors they consider.
```

Important factors:

```text
Patient mental state
Health literacy
Economic situation
Family/support system
Privacy and timing
Cultural/religious background
Urgency/risk level
Patient preference for information
```

SPIKES protocol was selected as a conceptual base:

```text
Setting
Perception
Invitation
Knowledge
Empathy
Strategy/Summary
```

Use this in the app by writing safe, gradual, action-focused result messages.

## 4. What Has Been Built

Current implemented baseline includes:

- Firebase Email/Password account creation, login, password reset, and logout.
- One-time medical safety disclosure after sign-in.
- Profile and baseline skin risk details.
- Local cached profile backup so age/contact are not lost when Firestore sync fails.
- Guided scan flow with patient details, body area, questionnaire, and camera/gallery image.
- On-device TensorFlow Lite model inference.
- Image preprocessing before AI review.
- Processing/review screen.
- Safe result categories and action guidance.
- Follow-up reminder planning.
- History grouped by patient/body area/lesion.
- Visual body map / 3D body reference support.
- Learn page with prevention/UV education.
- Profile page with account details, preferences, and safety/privacy wording.
- Medical blue-green UI theme and liquid-glass bottom navigation.
- Data-preserving run/install helper scripts.
- Thesis/report documentation and generated thesis diagrams.

## 5. Current Tech Stack

Mobile:

```text
Flutter
Dart
Material 3
camera
image_picker
image
path_provider
shared_preferences
sensors_plus
model_viewer_plus
```

AI / ML:

```text
Python
TensorFlow
Keras
MobileNetV2 transfer learning
TensorFlow Lite
tflite_flutter
HAM10000
selected PAD-UFES-20 clinical image sample
```

Cloud / backend:

```text
Firebase Core
Firebase Auth
Cloud Firestore
Local device file storage
```

Weather/UV:

```text
geolocator
http
current UV fetch/fallback logic
```

Documentation:

```text
python-docx
PIL/Pillow generated thesis diagrams
Markdown source files
DOCX/PDF reports
```

## 6. AI Scan Module Details

Active on-device model:

```text
ml/output/melanoma_risk_classifier.tflite
```

Model config:

```text
ml/output/model_config.json
```

Current model version:

```text
ham10000-padufes-melanoma-binary-20260831T071059Z
```

Task:

```text
Binary melanoma-risk classification
Classes: non_melanoma, melanoma
Image size: 224 x 224
Preprocessing: center_crop_sharpen
Active caution threshold: 0.45
Specialist threshold: 0.75
Borderline threshold: 0.30
```

After patient uploads/captures an image and clicks Scan:

```text
1. The app validates required scan fields.
2. The image is decoded.
3. Orientation correction is applied.
4. The image is center-cropped.
5. Mild sharpening is applied.
6. The image is resized to 224 x 224.
7. RGB input is prepared for the model.
8. TensorFlow Lite interpreter runs on device.
9. The model returns melanoma probability.
10. The app maps the probability and image quality into a safe result category.
11. The app combines AI output with questionnaire and baseline risk context.
12. The app displays patient-friendly action guidance.
13. The scan can be saved to history.
```

Important:

```text
The app should not show the raw AI output as a diagnosis.
The app should use result guidance and follow-up recommendations.
```

## 7. Current Model Test Evidence

Evidence file:

```text
docs/model_test_evidence_20260831.md
```

Selected clinical-photo sample:

```text
PAD-UFES-20 selected clinical close-up sample
```

Total tested:

```text
312 images
```

At threshold:

```text
0.45
```

Main result:

| Actual image group | Total | Correct | Wrong |
| --- | ---: | ---: | ---: |
| Melanoma images | 52 | 49 | 3 |
| Non-melanoma images | 260 | 214 | 46 |

Performance summary:

| Metric | Value |
| --- | ---: |
| Accuracy | 84.3% |
| Recall / melanoma catch rate | 94.2% |
| Precision | 51.6% |
| Specificity | 82.3% |

False warning breakdown:

| Non-melanoma group | Tested | False warnings |
| --- | ---: | ---: |
| Basal cell carcinoma | 52 | 8 |
| Nevus | 52 | 10 |
| Seborrheic keratosis | 52 | 10 |
| Solar or actinic keratosis | 52 | 8 |
| Squamous cell carcinoma | 52 | 10 |

How to explain false warnings in viva:

```text
Some non-melanoma lesions visually resemble melanoma-like patterns.
The model uses a cautious threshold to catch more melanoma cases.
This improves recall but increases false warnings.
The app handles this by giving non-diagnostic guidance and recommending review instead of making a diagnosis.
```

## 8. Important Files

Main Flutter app:

```text
lib/app/skinsafe_frontend.dart
```

Scan prediction service:

```text
lib/services/scan/scan_prediction_service.dart
```

User profile persistence:

```text
lib/services/firebase/user_profile_store.dart
```

Shared models:

```text
lib/shared/models
```

Firebase rules:

```text
firestore.rules
```

Model:

```text
ml/output/melanoma_risk_classifier.tflite
ml/output/model_config.json
ml/output/evaluation_metrics.json
```

3D mannequin:

```text
assets/models/medical_mannequin.glb
```

Run scripts:

```text
scripts/run_flutter_emulator.ps1
scripts/run_flutter_usb.ps1
scripts/install_debug_preserve_data.ps1
scripts/run_widget_tests.ps1
scripts/run_ai_api.ps1
scripts/check_ai_health.ps1
```

Thesis generator:

```text
scripts/generate_final_thesis.py
```

Major documentation:

```text
README.md
docs/INTERIM_2_REPORT.md
docs/INTERIM_2_REPORT.pdf
docs/SUPERVISOR_DISCUSSION_BRIEF.md
docs/FACTORS_AND_APP_USAGE.md
docs/FACTORS_AND_APP_USAGE.docx
docs/FULL_REF.pdf
docs/model_test_evidence_20260831.md
docs/FINAL_THESIS_DRAFT_KLDPP_KAKULANDALA.md
docs/FINAL_THESIS_DRAFT_KLDPP_KAKULANDALA_UPDATED_20260909_101605.docx
docs/generated_diagrams
```

## 9. Current Thesis / Report Work

Final thesis draft was generated using:

```text
scripts/generate_final_thesis.py
```

Latest generated Word thesis:

```text
docs/FINAL_THESIS_DRAFT_KLDPP_KAKULANDALA_UPDATED_20260909_101605.docx
```

Markdown thesis source:

```text
docs/FINAL_THESIS_DRAFT_KLDPP_KAKULANDALA.md
```

Generated thesis includes:

- Declaration
- Acknowledgement
- Abstract
- Table of Contents field
- List of Tables
- List of Figures
- Chapter 1: Introduction
- Chapter 2: Literature Review
- Chapter 3: Methodology
- Chapter 4: System Requirement Specification
- Chapter 5: Implementation and Design
- Chapter 6: Testing and Evaluation
- Chapter 7: Concluding Remarks
- References
- App screenshots
- Generated diagrams

Generated diagrams:

```text
docs/generated_diagrams/rich_picture.png
docs/generated_diagrams/conceptual_framework.png
docs/generated_diagrams/use_case_diagram.png
docs/generated_diagrams/system_architecture.png
docs/generated_diagrams/scan_activity_diagram.png
docs/generated_diagrams/class_model_diagram.png
docs/generated_diagrams/scan_sequence_diagram.png
```

If the DOCX cannot be overwritten, it is usually because Word has the file open. The generator saves a timestamped updated copy in that case.

## 10. Run Commands

List devices:

```powershell
flutter devices
```

Run on emulator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_flutter_emulator.ps1
```

Run on a specific emulator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_flutter_emulator.ps1 -DeviceId emulator-5554
```

Run on USB phone:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_flutter_usb.ps1 -DeviceId YOUR_DEVICE_ID
```

Install debug APK while preserving app data:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install_debug_preserve_data.ps1
```

Run widget tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_widget_tests.ps1
```

Optional local Python API for development only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_ai_api.ps1
```

Check optional API:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check_ai_health.ps1
```

Regenerate thesis:

```powershell
py scripts\generate_final_thesis.py
```

Important Windows note:

```text
Use py instead of python if the Microsoft Store Python alias causes problems.
If a path has spaces, quote it.
Do not type an unquoted path like D:\program files\flutter.
```

## 11. Firestore Rules

Current rules only allow a user to access their own profile and scan records:

```text
users/{userId}
users/{userId}/scan_records/{scanId}
```

Current rule file:

```text
firestore.rules
```

If Firestore gives permission errors, check:

```text
1. User is authenticated.
2. Data is written under users/{uid}.
3. Rules are deployed to the correct Firebase project.
4. The app config matches the Firebase project.
```

## 12. Known Issues / Things To Watch

### Medical Accuracy

The model is useful for screening support but is not clinically validated for diagnosis.

Do not promise:

```text
100% accuracy
confirmed cancer diagnosis
replacement for biopsy
replacement for dermatologist
```

### False Warnings

There are still false warnings. This is expected because the threshold is cautious to catch more melanoma examples.

### 3D Body Model

The app has 3D/visual body reference support, but realism and smoothness can still be improved with a better GLB asset and marker-coordinate handling.

### UV Feature

UV guidance is prevention awareness. It should not be described as a certified weather service.

### Data Clearing

The user was worried that data clears when running the app. Always use preserve-data scripts and avoid uninstall/clear-data commands unless explicitly requested.

### Black Screen / Emulator

There were earlier Android emulator black-screen issues. The project includes run/install adjustments and emulator rendering fixes. If it happens again, check Impeller/rendering settings and use the existing run scripts first.

### Firestore Permissions

Firestore permission denied errors happened before. The app added local profile caching so profile details still appear even when remote sync fails.

## 13. What Still Needs To Be Completed Before Public Store Release

The user said final app ID/package name, release signing, and store upload setup can be done later. Still, for public release these are required:

- Final package name/application ID.
- Release signing key.
- Final Firebase app configuration if package name changes.
- Privacy policy URL.
- Terms/safety/medical disclaimer page.
- Play Console declarations.
- Data safety form.
- Store screenshots and listing copy.
- Production app icon/name verification.
- Larger clinical validation if making medical claims.
- Real user usability testing.
- Dermatologist/supervisor review of result wording.
- More diverse dataset testing across skin tones, phone cameras, lighting, and lesion types.

## 14. Recommended Next Development Tasks

Best practical next tasks:

1. Run the current app on emulator and verify Scan -> Result -> Save -> History end-to-end.
2. Confirm age/contact/profile details persist after closing and reopening the app.
3. Improve 3D body model smoothness and marker placement if user wants more realism.
4. Add stronger image quality validation before inference.
5. Reduce false warnings through more data, threshold calibration, and preprocessing checks.
6. Polish History full visual body-map mode.
7. Verify Firestore security rules with real authenticated users.
8. Update thesis screenshots after final UI changes.
9. Prepare privacy policy and release checklist when the user decides to publish.

## 15. AI Agent Safety Instructions

When another AI agent continues:

- Read this file first.
- Read `README.md`.
- Read `docs/model_test_evidence_20260831.md`.
- Read `ml/output/model_config.json`.
- Do not undo existing user changes.
- Do not delete downloaded datasets or model outputs unless the user explicitly asks.
- Do not add Sinhala text into codebase files.
- Do not use destructive git commands.
- Do not claim the app is a medical-grade diagnostic system.
- Prefer editing with patches and then verify with `dart analyze`, `flutter test`, or relevant scripts.

## 16. Short Explanation For Supervisor

SkinSafe is a melanoma skin cancer detection and prevention support mobile application. It guides a user through patient details, lesion location, questionnaire, and photo capture. After the user clicks Scan, the app preprocesses the image and runs an on-device TensorFlow Lite model. The result is combined with image quality, questionnaire flags, and baseline risk context. The app then gives safe action guidance such as low risk, monitor closely, caution advised, or specialist review recommended. It saves scan history by patient, body area, and lesion spot so the same lesion can be reviewed again later.

The main research value is not only the AI model. It is the full patient-support workflow: guided scan, safe communication, history, follow-up reminders, prevention education, UV guidance, and ethical handling of sensitive cancer-related warnings.

## 17. One-Paragraph Project Status

SkinSafe is currently a working Flutter/Firebase/TensorFlow Lite melanoma screening-support application with guided scan flow, on-device AI review, safe result communication, history tracking, body map support, prevention education, UV guidance, profile caching, and generated thesis documentation. The current model has strong melanoma catch rate on the selected PAD-UFES sample but still has false warnings and is not clinically validated. The next best work is end-to-end verification, further model/data improvement, image quality validation, 3D body-map polish, and release-preparation tasks when the user is ready.
