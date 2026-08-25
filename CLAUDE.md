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

- Flutter app, published on Google Play, currently at `version: 1.2.0+11`
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
    qr_code_screen.dart      Sticker studio: theme picker, sheet layout, print
    legal_documents_screen.dart
  services/
    auth_service.dart        Sign up/in/out, account deletion, FCM token writes
    firestore_service.dart   All Firestore reads/writes (vehicles, QR, notifications)
    fcm_service.dart         Push receipt, local notifications, reminder scheduling
    notification_payload.dart      FCM data-payload contract + reminder ID derivation
    notification_navigation_service.dart  Deep-link a tapped notification to a screen
  theme/
    app_theme.dart           ALL design tokens + ThemeData (single source)
  utils/
    qr_payload_builder.dart  Builds the URL encoded into the QR
    sticker_renderer.dart    Canvas-drawn themeable sticker (preview + export)
    sticker_sheet.dart       Lays stickers onto a page; PDF + system print dialog
    notification_visuals.dart  Alert reason -> icon, colour, severity, guidance
    qr_encryption.dart       AES helper — CURRENTLY UNUSED, see Known issues
    vehicle_registration_validator.dart  Indian plate regex (standard + Bharat series)
  widgets/
    ui_kit.dart              Shared components (cards, rows, empty states, ...)
    hero_header.dart         Brand gradient surface + glass panel
    qr_visual.dart           Canonical QR styling, hero plinth, showcase panel
    vehicle_panel.dart       The swipeable vehicle rail on the home hero
    admob_banner.dart
docs/                        Architecture and contract docs — read before changing behaviour
assets/
  fonts/                     Inter, Plus Jakarta Sans, Noto Sans Kannada (subset)
  images/qr_template.svg     Legacy sticker artwork — NO LONGER USED, see Known issues
  audio/avahanaa_alarm.wav   Alarm sound — CURRENTLY UNUSED, see Known issues
tool/verify_sticker_scan.py  Decodes exported stickers under simulated scan conditions
test/                        Only notification_payload_test.dart is meaningful
```

**There are two backends, and the one in this repo is not the one running.**

`functions/` + `public/` + `firestore.rules` here (added `79b7720`) are
contract-correct but **have never been deployed**. What actually serves
`avahanaa.com` is a separate repo, `github.com/ShayanBanerjee/Avahanaa-Web`,
whose scan page reads `users/{uid}` — `fcmToken` and `phoneNumber` — directly
from the anonymous scanner's browser. Both repos target the same Firebase
project (`congestion-free`) with conflicting hosting configs, so **a
`firebase deploy` from either silently clobbers the other**.

Read `docs/web_backend_sync.md` before touching anything under `functions/`,
`public/`, `firestore.rules`, or `firebase.json`. The contract both sides owe
the app is `docs/critical_notification_payload_contract.md` and
`docs/backend_contract.md` — treat those as an API you do not control
unilaterally, because QR URLs printed on windshields are permanent.

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
- **All design tokens live in `lib/theme/app_theme.dart`** — `AppColors`,
  `AppSpacing`, `AppRadius`, `AppShadows`, `AppMotion`, `AppText`, and
  `AvahanaaTheme.light()`. Screens must not hardcode hex, spacing or text
  styles; if a shade is missing, add it to the token file so the whole app
  moves together. The palette is `#2563EB` primary blue, `#10B981` green,
  `#C81B30` alert crimson, `#F8FAFC` background, `#0F172A` text, `#E2E8F0`
  borders. The neutrals are blue-tinted slate rather than pure grey, so they
  sit with the brand blue instead of reading faintly green next to it.
  Radius 12 for inputs/buttons, 16 for cards, 24 for hero surfaces.
- Shared components live in `lib/widgets/ui_kit.dart` (cards, list rows, empty
  states, stat tiles, plate badge, skeletons, snackbars), `hero_header.dart`
  (the brand gradient surface), `qr_visual.dart` (the single definition of how
  a QR is drawn, plus `QrShowcasePanel`) and `vehicle_panel.dart` (the home
  hero's vehicle rail). Compose these instead of hand-rolling containers.
- **Sticker designs are data, not code paths.** A look is a `StickerTheme`
  (colours) on a `StickerLayout` (geometry) in `sticker_renderer.dart`. Add a
  row, never a new `case` in the painter — and never colour the code itself.
- Fonts are bundled: **Inter** for body/labels, **Plus Jakarta Sans** for
  display. Both are variable fonts, so `AppText` sets `fontVariations` as well
  as `fontWeight` — setting only `fontWeight` renders at the default axis
  position on some Android builds. The theme previously declared
  `SF Pro Display`, which was never shipped and silently fell back to Roboto.
- Config that varies by environment uses `String.fromEnvironment` with a safe
  default (see `qr_payload_builder.dart`), passed via `--dart-define`.
- Indian vehicle plates: always validate through
  `VehicleRegistrationValidator`, never re-implement the regex.

## Commands

```bash
flutter analyze                 # baseline: zero issues — a new lint is a regression
flutter test
flutter run
flutter build appbundle --release   # needs android/key.properties (gitignored)

# Scan-verify the printable sticker after any change to its painter or themes.
STICKER_OUT=/tmp/stickers flutter test test/sticker_renderer_test.dart
python3 tool/verify_sticker_scan.py /tmp/stickers
```

The analyze baseline as of Aug 2026 is **zero issues** — zero errors, zero
warnings, zero lints. The previous baseline of 20 info-level issues
(`use_build_context_synchronously` in `profile_screen.dart`, deprecated
`withOpacity`, deprecated `Share.shareXFiles`) was cleared during the v1.1.0 UI
rebuild. Keep it at zero: a new lint is now a regression, not a rounding error.

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
4. `firestore.rules` / `firestore.indexes.json` now exist and are wired in
   `firebase.json`, but **nothing here is deployed** — production still runs
   the 2025 `Avahanaa-Web` code, which leaks owner contact data to the scanner.
   This is the highest-severity open item: `docs/web_backend_sync.md`.
5. `assets/images/qr_template.svg` is legacy artwork that nothing references.
