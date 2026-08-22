# Avahanaa — Claude Code project context

## What this app is (the business problem)

A vehicle owner in Bangalore parks a car/bike. Things then go wrong in ways the
owner cannot see:

- The vehicle blocks someone in, and a person stuck behind it gets angry enough
  to damage it.
- A traffic cop is about to tow or seize it for a parking violation.
- A passer-by notices damage, a broken window, lights left on, a fuel leak.

In every case somebody *at* the vehicle wants to reach the owner, and the owner
is not there. The pre-existing solution is writing a phone number on the
dashboard, which leaks a personal number to strangers (spam, harassment,
stalking).

**Avahanaa's solution:** a QR sticker on the windshield. Anyone — no app
install, Google Lens is enough — scans it, lands on a clean web page, picks a
reason, and sends an alert. The owner gets a push notification on their phone
and rushes to the vehicle. **No phone number, email, or identity is ever
revealed to the scanner, in either direction.** The value is a fast, anonymous,
one-way-to-contact channel with an urgency guarantee.

The product bet is *urgency*: an alert that arrives silently is worthless when
someone is standing next to your car deciding whether to key it. Getting from
"scan" to "owner is physically moving" in under a minute is the whole product.
See `docs/alert_escalation_options.md` — that is the single most important
design document in this repo.

Name note: the Firebase project and Android application ID still say
`congestion-free` / `com.avahanaa.congestion_free`. That is the original project
name. **Never change the application ID** — it is the published Play Store
identity.

## Current state

- Flutter app, published on Google Play, currently at `version: 1.0.0+9`
  (`pubspec.yaml`). It has passed Play review, including a round of scrutiny on
  the notification behaviour — do not casually reintroduce anything that was
  softened to get through review without reading
  `docs/play_store_compliance.md`.
- Backend is Firebase: Auth (email/password + email verification), Firestore,
  Cloud Messaging.
- Monetised with AdMob banners (`lib/widgets/admob_banner.dart`).

## Repo layout

```
lib/
  main.dart                  App root, theme, AuthGate, FCM background handler
  firebase_options.dart      Generated — do not hand-edit
  models/                    UserModel, VehicleModel, NotificationModel
  screens/
    auth/                    login, signup, verify_email, forgot_password
    home_screen.dart         Bottom nav shell + home tab (largest screen file)
    notifications_screen.dart
    profile_screen.dart      Vehicle list, account settings (largest file, 1047 lines)
    qr_code_screen.dart      QR render, SVG sticker template, share/save
    legal_documents_screen.dart
  services/
    auth_service.dart        Sign up/in/out, account deletion, FCM token writes
    firestore_service.dart   All Firestore reads/writes (vehicles, QR, notifications)
    fcm_service.dart         Push receipt, local notifications, reminder scheduling
    notification_payload.dart      FCM data-payload contract + reminder ID derivation
    notification_navigation_service.dart  Deep-link a tapped notification to a screen
  utils/
    qr_payload_builder.dart  Builds the URL encoded into the QR
    qr_encryption.dart       AES helper — CURRENTLY UNUSED, see Known issues
    vehicle_registration_validator.dart  Indian plate regex (standard + Bharat series)
  widgets/admob_banner.dart
docs/                        Architecture and contract docs — read before changing behaviour
assets/
  images/qr_template.svg     The printable sticker artwork; QR is composited into a slot
  audio/avahanaa_alarm.wav   Alarm sound — CURRENTLY UNUSED, see Known issues
test/                        Only notification_payload_test.dart is meaningful
```

**The scan-side web page and the FCM sender are NOT in this repo.** They live at
`avahanaa.com` (Firebase Hosting + Cloud Functions in a separate project or
directory). This repo only ever *reads* alerts. The contract between the two is
`docs/critical_notification_payload_contract.md` and
`docs/backend_contract.md` — treat those as an API you do not control
unilaterally.

## Data model (Firestore)

```
users/{userId}
  email, phoneNumber, fcmToken, fcmTokenUpdatedAt,
  primaryVehicleId, notificationsEnabled, createdAt, updatedAt
  qrCodeId, carDetails      <- LEGACY single-vehicle fields, still dual-written

users/{userId}/vehicles/{vehicleId}
  userId, color, carModel, licensePlate, assetNumber,
  qrCodeId, isActive, notificationsEnabled, createdAt, updatedAt

qrCodes/{qrCodeId}          <- top-level, readable by the scan page
  userId, vehicleId, isActive, payloadVersion, payload, metadata{}, timestamps
  metadata carries ONLY vehicle colour/model/plate — never owner contact info

notifications/{notificationId}
  qrCodeId, userId, vehicleId, reason, message, status, read, sentAt, readAt
```

The multi-vehicle migration is mid-flight: Phase 1/2 (dual-write + lazy
backfill) is live via `FirestoreService.bootstrapVehiclesFromLegacyUser`.
Legacy `users.carDetails` / `users.qrCodeId` are still written by
`upsertVehicle(syncLegacyUserFields: true)` and
`ensureVehicleQrCode(syncLegacyUserFields: true)`. Do not delete legacy writes
without doing Phase 4 in `docs/multi_vehicle_schema_migration_plan.md`.

`qrCodes` is deliberately top-level and not nested under the user, because the
public scan page must resolve a QR without knowing the owner. Keep it that way,
and keep owner PII out of it.

## The alert path, end to end

1. Stranger scans the sticker → `https://avahanaa.com/n/{qrCodeId}` (short
   route, built in `qr_payload_builder.dart`; falls back to
   `/index.html?page=notify&qr={id}&v=3`).
2. Web page reads `qrCodes/{qrCodeId}`, requires `isActive == true`, shows the
   vehicle description and a reason picker.
3. Backend writes `notifications/{id}` and sends FCM to `users/{userId}.fcmToken`
   with the data keys in `docs/critical_notification_payload_contract.md`.
4. App receives it:
   - Foreground → `FCMService._handleForegroundMessage`
   - Background/terminated → `_firebaseMessagingBackgroundHandler` in `main.dart`,
     which only shows a local notification when `message.notification == null`
     (data-only), because Android auto-displays notification payloads.
5. `FCMService.showNotificationForMessage` dedupes by `notificationId`, shows the
   alert on the `avahanaa_critical_alerts_v2` channel, then schedules **two
   escalating reminders at +3 min and +15 min** from `sentAt`.
6. Reminders are cancelled when the alert is read/tapped
   (`cancelNotificationLifecycleById`), and re-synced from Firestore unread docs
   on app start (`_syncReminderStateFromFirestore`).

Reminder state persists to a JSON file in the app support dir
(`avahanaa_notification_orchestrator_state_v1.json`) so dedupe and cancellation
survive process death. Reminder notification IDs are *derived* from
`notificationId.hashCode` (`NotificationReminderIds`) rather than stored, so the
background isolate can cancel them without reading state.

## Conventions to follow

- **No state-management package.** The app uses `StatefulWidget` +
  `StreamBuilder` over Firestore streams. Do not introduce Provider/Riverpod/Bloc
  without being asked.
- **All Firestore access goes through `FirestoreService`.** Screens never touch
  `FirebaseFirestore.instance` directly. `AuthService` and `FCMService` are the
  only exceptions, and only for their own concerns.
- Services swallow errors with `debugPrint`/`log` and return null/empty for
  reads, but `throw 'Human readable string'` for writes the user initiated.
  Screens catch that string and show a `SnackBar`. Keep that split.
- Theme lives in `main.dart`. Colours are inline hex constants; the recurring
  palette is `#2563EB` primary blue, `#10B981` green, `#DC2626` alert red,
  `#F9FAFB` background, `#1F2937` text, `#E5E7EB` borders. Radius 12 for
  inputs/buttons, 16 for cards, 24 for hero surfaces.
- Config that varies by environment uses `String.fromEnvironment` with a safe
  default (see `qr_payload_builder.dart`), passed via `--dart-define`.
- Indian vehicle plates: always validate through
  `VehicleRegistrationValidator`, never re-implement the regex.

## Commands

```bash
flutter analyze                 # baseline: 20 info-level lints, 0 errors/warnings
flutter test
flutter run
flutter build appbundle --release   # needs android/key.properties (gitignored)
```

The analyze baseline as of Aug 2026 is **20 info-level issues, zero errors and
zero warnings** — mostly `use_build_context_synchronously` in
`profile_screen.dart`, deprecated `withOpacity`, and the deprecated
`Share.shareXFiles` API in `qr_code_screen.dart`. Do not add to that count. When
you touch a file that already has lints, fixing them is welcome but optional;
introducing a new one is not.

Release builds require `--dart-define` values for the QR host if not using the
defaults. `android/key.properties` is intentionally absent from git; the build
fails loudly on release without it (`android/app/build.gradle.kts`).

## Hard rules

- **Never commit signing material.** `*.jks`, `*.keystore`, `key.properties` are
  gitignored. An upload keystore was committed once and removed in `10626d0` —
  do not repeat it.
- **Never put owner PII into `qrCodes` docs or QR payloads.** The whole product
  promise is that the scanner learns nothing about the owner. The QR encodes an
  opaque ID and nothing else.
- **Never bump `applicationId`** (`com.avahanaa.congestion_free`).
- Bump `version:` in `pubspec.yaml` for every Play upload — Play rejects
  duplicate version codes.
- Changing the FCM data contract requires changing the out-of-repo sender first,
  or in a backward-compatible additive way. Old app versions stay installed.
- `lib/firebase_options.dart` and `android/app/google-services.json` are
  generated by FlutterFire; regenerate rather than edit.

## Known issues / open threads

Kept in `docs/known_issues.md` with detail. The short list:

1. `AndroidManifest.xml` declares `default_notification_channel_id` as the
   **legacy** `congestion_free_channel`, while the app's critical channel is
   `avahanaa_critical_alerts_v2`. Notification-payload pushes handled by the
   system land on the quieter legacy channel.
2. `assets/audio/avahanaa_alarm.wav` is shipped but referenced nowhere. The
   loud-buzzer feature is unbuilt. See `docs/alert_escalation_options.md`.
3. `lib/utils/qr_encryption.dart` is dead code with a hardcoded default AES key
   committed in source. Delete it or wire it up — do not ship the default key.
4. No `firestore.rules` or `firestore.indexes.json` in this repo, and
   `firebase.json` has no rules/indexes/hosting config. Security rules are
   managed out-of-band, which means they are unreviewed here.
5. `test/` covers only the notification payload parser. The QR payload builder
   and plate validator are pure functions and trivially testable.
6. 20 info-level analyzer lints, including three
   `use_build_context_synchronously` clusters in `profile_screen.dart` that are
   real async-gap risks, and a deprecated `share_plus` API call.
