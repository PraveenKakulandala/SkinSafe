# SkinSafe Publish Checklist

Last updated: August 6, 2026

This checklist covers the remaining manual steps outside the Flutter codebase for publishing SkinSafe.

## 1. Identity and Branding

- Choose a final Android package name and iOS bundle identifier.
- Regenerate Firebase configuration after changing app identifiers.
- Replace the default launcher icon with your final production icon.
- Prepare Play Store and App Store screenshots, feature graphics, and app descriptions.

## 2. Legal and Policy

- Host a public privacy policy URL.
- Host public terms of use or acceptable use text.
- Make sure the policy explains:
  - account data
  - lesion photos
  - generated illustrations
  - scan history
  - location use for UV guidance
- Keep the in-app medical disclaimer aligned with the hosted policy.

## 3. Google Play Console

- Create the Play Console app listing.
- Complete the Data safety form.
- Complete the Health apps declaration form.
- If required for your developer account type, complete organization verification.
- Upload the release `.aab`.
- Fill content rating, target audience, and app access sections.

## 4. Apple App Store Connect

- Create the App Store Connect app entry.
- Set the final bundle identifier and signing.
- Upload the release build from Xcode or Transporter.
- Complete privacy nutrition labels.
- Declare regulated medical device status accurately.

## 5. Release Engineering

- Create a release keystore for Android.
- Configure `key.properties` and release signing.
- Build a release Android App Bundle:
  - `flutter build appbundle`
- Build an iOS release archive from Xcode.

## 6. Backend and Operations

- Host the AI prediction API in a production environment.
- Replace local-only prediction URLs with production environment configuration.
- Monitor API uptime, logs, and failure rates.
- Define backup and retention rules for scan data.

## 7. Final Safety Review

- Use non-diagnostic wording in store descriptions and onboarding.
- Avoid claims such as:
  - guaranteed detection
  - confirmed melanoma diagnosis
  - replacement for clinicians
- Keep wording focused on:
  - screening support
  - follow-up guidance
  - self-monitoring

## 8. Pre-Submission Test Pass

- Test sign up, login, reset password, and logout.
- Test scan from camera and gallery.
- Test AI success and AI failure states.
- Test saving history and re-opening history.
- Test follow-up comparison and ghost-reference flow.
- Test permissions:
  - camera
  - photos/media
  - location

