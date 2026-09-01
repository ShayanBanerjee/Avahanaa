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
- Monetised three ways since Sep 2026: one AdMob banner in the app shell,
  rewarded ads that buy alert credits, and Avahanaa Plus subscriptions.
  `docs/monetization.md` is the design and the Play Console setup that has to
  happen before any of it works.

## Repo layout

```
lib/
  main.dart                  App root, theme, AuthGate, FCM background handler
  firebase_options.dart      Generated — do not hand-edit
  models/                    UserModel, VehicleModel, NotificationModel,
                             AlertWallet (the alert budget), ScanLocation,
                             QuietHours, AlertInsights
  screens/
    auth/                    login, signup, verify_email, forgot_password
    home_screen.dart         Bottom nav shell + home tab (largest screen file)
    notifications_screen.dart
    profile_screen.dart      Vehicle list, account settings (largest file, 1047 lines)
    qr_code_screen.dart      Sticker studio: theme picker, sheet layout, print
    legal_documents_screen.dart
    plans_screen.dart          Paywall: ad top-up + the three subscription tiers
  services/
    auth_service.dart        Sign up/in/out, account deletion, FCM token writes
    firestore_service.dart   All Firestore reads/writes (vehicles, QR, notifications)
                             + the shared-listener cache, see Conventions
    avahanaa_api.dart        HTTPS client for avahanaa.com/api/* (wallet, billing,
                             self-test) — the three things a client may not decide
    billing_service.dart     Google Play subscriptions; hands tokens to the backend
    rewarded_ad_service.dart Rewarded ads; mints the SSV nonce
    alert_credits.dart       The one implementation of "watch an ad, get a credit"
    alert_readiness.dart     Will this phone actually wake its owner up?
    ad_gate.dart             One notifier: may this app show ads right now
    shared_stream.dart       One upstream listener, many subscribers, replayed
    fcm_service.dart         Push receipt, local notifications, reminder scheduling
    notification_payload.dart      FCM data-payload contract + reminder ID derivation
    notification_navigation_service.dart  Deep-link a tapped notification to a screen
  theme/
    app_theme.dart           ALL design tokens + ThemeData (single source)
  utils/
    alert_share.dart         Forward an alert to whoever is nearer the car
    qr_payload_builder.dart  Builds the URL encoded into the QR
    sticker_renderer.dart    Canvas-drawn themeable sticker (preview + export)
    sticker_sheet.dart       Lays stickers onto a page; PDF + system print dialog
    notification_visuals.dart  Alert reason -> icon, colour, severity, guidance
    qr_encryption.dart       AES helper — CURRENTLY UNUSED, see Known issues
    vehicle_registration_validator.dart  Indian plate regex (standard + Bharat series)
  widgets/
    ui_kit.dart              Shared components (cards, rows, empty states, ...)
    alert_credit_meter.dart  The balance, inline on the hero or as a card
    alert_readiness_card.dart  Appears only when alerts cannot reach this phone
    scan_location_card.dart  Where the vehicle was, when the scanner shared it
    alert_insights_card.dart How fast you answer, and where alerts come from
    hero_header.dart         Brand gradient surface + glass panel
    qr_visual.dart           Canonical QR styling, hero plinth, showcase panel
    vehicle_panel.dart       The swipeable vehicle rail on the home hero
    admob_banner.dart
docs/                        Architecture and contract docs — read before changing behaviour
assets/
  fonts/                     Inter, Plus Jakarta Sans, Noto Sans Kannada (subset)
  images/qr_template.svg     Legacy sticker artwork — NO LONGER USED, see Known issues
  audio/avahanaa_alarm.wav   Alarm sound. The copy the app actually plays lives
                             in android/app/src/main/res/raw/ — Android will not
                             take a notification sound from Flutter assets.
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
  quietHours{enabled,startMinute,endMinute}, timezoneOffsetMinutes
                            <- client-written preferences. The backend reads
                               the offset to know what "22:00" means.
  plan, planProductId, planExpiresAt, planUpdatedAt,
  alertCredits, freeAlertsUsed, cycleStartedAt,
  lifetimeAlertsReceived, lifetimeAdsWatched
                            <- the alert budget. ALL server-written; the rules
                               deny the client every one of these fields.

users/{userId}/vehicles/{vehicleId}
  userId, color, carModel, licensePlate, assetNumber,
  qrCodeId, isActive, notificationsEnabled, createdAt, updatedAt

qrCodes/{qrCodeId}          <- top-level, readable by the scan page
  userId, vehicleId, isActive, payloadVersion, payload, metadata{}, timestamps
  metadata carries ONLY vehicle colour/model/plate — never owner contact info

notifications/{notificationId}
  qrCodeId, userId, vehicleId, reason, message, status, read, sentAt, readAt
  deliveryTier              <- 'full' | 'quiet', decided once at write time
  location                  <- {lat, lng, accuracyM} rounded to ~110m, or null

adRewards/{transactionId}   <- one settled AdMob SSV callback. Server-only.
purchaseTokens/{sha256}     <- which account claimed a Play purchase. Server-only.
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
5b. **The alert budget decides how loud step 5 is.** `/api/notify` spends one
   alert against the owner's wallet and stamps the notification `full` or
   `quiet`; the push carries it as a `tier` data key. `quiet` means a
   default-importance channel and no reminders — never a missing alert, and
   never for an `emergency`, which is checked before the balance is. An absent
   or unknown `tier` means `full`. **Quiet hours use the same mechanism** —
   inside the window a non-emergency is forced to `quiet`, never suppressed.
   See `docs/monetization.md`.
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
- **Every user-facing string goes through `AppL10n`.** English and Kannada ARBs
  live in `lib/l10n/`; `AppL10n.of(context)` in widgets. Two exceptions, both
  deliberate:
  - Code with no `BuildContext` — models, static validators, the services that
    `throw` their own error strings — uses `appL10n` from
    `lib/l10n/l10n_global.dart`, which resolves through the navigator and falls
    back to English. Do not reach for it where a context exists.
  - Models and enums that are also read from the background isolate keep their
    English form (`reasonText`, `ownerLabel`, `StickerStyle.label`) *alongside*
    a localized accessor (`reasonTextIn(l10n)`, …). The English one names
    exported files and builds notification actions before a locale exists.

  `DateFormat` must be given `Localizations.localeOf(context).toLanguageTag()`
  — untold, it silently keeps speaking English. `initializeDateFormatting()`
  runs before `runApp`; without it a non-default locale throws rather than
  degrades. `test/l10n_test.dart` fails the build when the two ARBs drift.
- **Two themes.** `AvahanaaPalette.light` / `.dark`, swapped by
  `ThemeController` immediately *before* the tree rebuilds. Because tokens are
  getters over one active palette, a `const` widget would keep painting the old
  colours — so this app's own widgets are deliberately not `const`. Framework
  widgets are fine either way.

  Anything drawn on a surface that does **not** follow the theme — the brand
  gradient, the alert banner, a vehicle's paint swatch — must use pinned
  colours (`AppColors.inkOnLightFill`, `inkOnAlertFill`, `onDark`,
  `AppPrint.*`). Getting this wrong is invisible in light mode and glaring at
  night. `test/contrast_test.dart` gates both palettes.
- **Never cache a shared stream in a `late final` and wrap it.** `SharedStream`
  hands out one multi-subscriber, replaying, stable-identity stream; that is
  exactly what `StreamBuilder` needs. Wrapping it in `asBroadcastStream()` kills
  the source the first time the widget unmounts (the hero froze on a stale
  balance for a whole session), and a single-subscription view throws on the
  second listen. `test/shared_stream_test.dart` pins all three properties.
- **Firestore listeners are shared, not per-screen.** The shell keeps all three
  tabs alive in an `IndexedStack`, so every tab's `StreamBuilder` is mounted at
  once — which is how `users/{uid}` came to have four simultaneous listeners.
  `FirestoreService` memoises the streaming reads and replays the last value to
  each new subscriber. Add a new `stream*` method through `_shared(key, ...)`,
  and if you ever add a third sign-out path, call
  `FirestoreService.disposeSharedStreams()` from it.
- **There is exactly one ad slot**, in the app shell above the nav bar, and it
  removes itself for subscribers via `adsAllowed` in `ad_gate.dart`. Do not add
  an `AdMobBanner` to a screen: with the tabs all alive, a second one is a
  second simultaneous ad load for a slot nobody can see. Panic surfaces carry
  no ads at all.
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
  moves together.

  **Graphite and amber since Sep 2026**, replacing the corporate blue. The hero
  is a machined near-black (`MetalPalette.brand`) with one warm bronze corner —
  the ramp's `catchLight` — so the surface reads as lit rather than filled.

  `primary` is a deep bronze `#8A5A18` in daylight and a bright amber
  `#E8A33D` at night. It has to be both, because `primary` is used as ink on
  white *and* as a fill under white: one bright amber cannot do both, and
  `#E8A33D` on white is 1.9:1.

  The neutrals are warm greys for the same reason they used to be blue-slate —
  a cool grey beside bronze reads faintly green. `warning` is burnt orange
  `#C2410C`, moved so it stays distinguishable now that the brand is warm.
  `success` `#10B981` and alert crimson `#C81B30` are unchanged.

  `AppPrint.heroGradient` carries the flat three-stop version of the same ramp,
  so the app and the printed sticker are one brand. Changing it means
  re-running the sticker scan verification — the QR itself is never touched,
  but the band around it is.
- Radius 12 for inputs/buttons, 14 for cards, 20 for hero surfaces. Card
  padding is 24, matching the web's `.card-body`.
- **The app and `avahanaa.com` are one brand.** The web's theme layer
  (`Avahanaa-Web/index.html`) carries the same tokens as `app_theme.dart`;
  primary buttons are graphite in both, bronze is the accent in both, and green
  is a status in both. A change to the palette here that is not mirrored there
  is a visible mismatch to anyone who scans a sticker and then opens the app.
- Shared components live in `lib/widgets/ui_kit.dart` (cards, list rows, empty
  states, stat tiles, plate badge, skeletons, snackbars), `hero_header.dart`
  (the brand gradient surface), `qr_visual.dart` (the single definition of how
  a QR is drawn, plus `QrShowcasePanel`) and `vehicle_panel.dart` (the home
  hero's vehicle rail). Compose these instead of hand-rolling containers.
- **Sticker designs are data, not code paths.** A look is a `StickerTheme`
  (colours) on a `StickerLayout` (geometry) in `sticker_renderer.dart`. Add a
  row, never a new `case` in the painter — and never colour the code itself.
- The bundled **Noto Sans Kannada** subset now serves the app UI as well as the
  printed sticker, so any string added to `app_kn.arb` renders on every device.
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
- **Never meter an emergency, and never let a spent budget silence an alert
  outright.** The whole monetisation design rests on those two carve-outs; read
  `docs/monetization.md` before touching `spendAlertBudget` or `AlertTier`.
- **Never grant a credit or a subscription from the client.** Credits come from
  AdMob's signed server-side-verification callback; subscriptions come from the
  Play Developer API. The rules deny the client those fields, and that is
  load-bearing rather than defence in depth.
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
