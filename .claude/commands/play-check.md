---
description: Pre-upload Google Play policy check on the current changes
---

Run a Google Play policy review of the current changes before upload.

Use the `play-compliance` agent's checklist, or do it directly. Read
`docs/play_store_compliance.md` first, then examine:

- `git diff` against `main` for the actual changes
- `android/app/src/main/AndroidManifest.xml` for added permissions
- Notification channel/sound/full-screen-intent behaviour in
  `lib/services/fcm_service.dart`
- New fields written to `users`, `vehicles`, or `notifications` versus the Data
  Safety declaration
- `AuthService.deleteAccount` coverage of every user-owned collection
- `AdMobBanner` placement relative to primary actions and the alert path
- Any secrets, keystores, or API keys in the diff
- Owner PII leaking into `qrCodes` or the QR payload

Also confirm the mechanical prerequisites:

- `version:` in `pubspec.yaml` is bumped
- `flutter analyze` is clean

Finish with a plain verdict — ship / ship with fixes / do not ship — and order
findings by severity. Flag judgement calls as judgement calls.
