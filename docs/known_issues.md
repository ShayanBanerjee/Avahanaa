# Known issues and open threads

Ordered roughly by risk. Update this file when one is closed.

## 1. Notification channel mismatch in the manifest

`android/app/src/main/AndroidManifest.xml` declares:

```xml
<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
           android:value="congestion_free_channel" />
```

but the app's real critical channel is `avahanaa_critical_alerts_v2`
(`lib/services/fcm_service.dart`). Any push that carries a `notification` block
is auto-displayed by the system in background/terminated state, and lands on the
**legacy quiet channel** rather than the max-importance one. The reminder logic
never runs for those either, because `main.dart` only calls
`showNotificationForMessage` when `message.notification == null`.

Fix: point the manifest at the current critical channel, and/or make the sender
emit data-only pushes so the app fully controls presentation. The two must be
decided together with the out-of-repo sender.

## 2b. Legacy sticker artwork is bundled but unused (Aug 2026)

`assets/images/qr_template.svg` (230KB) was the old composited sticker. The
sticker is now drawn on a canvas by `lib/utils/sticker_renderer.dart`, and
nothing references the SVG. The `flutter_svg` dependency was removed with it.

The file is deliberately left in place rather than deleted — it is the owner's
artwork and restoring the old design should stay a one-line decision. If it is
not coming back, delete it and the app bundle drops 230KB.

## 2. The alarm sound is shipped but unused

`assets/audio/avahanaa_alarm.wav` is bundled via `pubspec.yaml` and referenced
nowhere in `lib/`. The "loud buzzer" feature is unbuilt. Android custom
notification sounds must live in `android/app/src/main/res/raw/`, not in Flutter
assets. See `docs/alert_escalation_options.md` §Stage 1.

## 3. Dead AES helper with a hardcoded key

`lib/utils/qr_encryption.dart` is not imported anywhere. It contains a committed
default key and IV:

```dart
static const String _defaultKey = '0123456789abcdef0123456789abcdef';
static const String _defaultIv  = 'abcdef9876543210';
```

The QR payload no longer carries encrypted data — it is an opaque ID URL — so
the file is obsolete. Delete it, or if encryption comes back, make the key
required via `--dart-define` with no default so a missing key fails the build.

## 4. Firestore rules and indexes are not in this repo

`firebase.json` configures only the Flutter platform mapping. There is no
`firestore.rules`, no `firestore.indexes.json`. The rules protecting `qrCodes`
(public read) and `notifications` (owner-only) are therefore unreviewable here
and undeployable from here.

This is the highest-severity item on the list, because `qrCodes` is
publicly readable by design and `notifications` is written by an unauthenticated
scan flow. Bring the rules into the repo, with tests.

Indexes needed by existing queries:
- `notifications(userId ASC, sentAt DESC)`
- `notifications(userId ASC, read ASC)`
- `notifications(userId ASC, vehicleId ASC, sentAt DESC)` — used by
  `streamVehicleNotifications`

## 5. Unbounded reads in notification counters

`getUnreadNotificationCount` and `getNotificationStats` fetch entire result sets
and call `.length`. `streamUnreadNotificationCount` streams every unread doc just
to count them, and it is attached at the top of `HomeScreen.build`, so it stays
open the whole session. Use aggregate `count()` queries instead.

## 6. Thin test coverage — PARTLY CLOSED (Aug 2026)

`QrPayloadBuilder` and `VehicleRegistrationValidator` are now covered by
`test/qr_payload_builder_test.dart` and
`test/vehicle_registration_validator_test.dart`, including Bharat-series plates
and the short-route vs query fallback. `test/ui_kit_layout_test.dart` pumps the
shared design-system components at 320dp across 1.0x–2.0x text scale and fails
on any overflow.

Still open: no coverage of the screens themselves, because they construct
`FirebaseAuth.instance.currentUser` and Firestore streams at build time. Making
them testable needs an injection seam in `FirestoreService`/`AuthService`.

## 7. Legacy dual-write is still on

`upsertVehicle` and `ensureVehicleQrCode` still write `users.carDetails` and
`users.qrCodeId`. That was Phase 1/2 of the multi-vehicle migration. Phase 4
cleanup in `docs/multi_vehicle_schema_migration_plan.md` has not run. Until it
does, a user's legacy fields reflect whichever vehicle was touched last, which
is misleading if anything reads them.

## 8. Analyzer baseline is 20 info-level lints

Not zero. `flutter analyze` reports 20 issues, no errors or warnings. The ones
worth actually fixing:

- `use_build_context_synchronously` across `profile_screen.dart` (lines 679-906),
  `signup_screen.dart:115`, `qr_code_screen.dart:379,395`. These are genuine
  async-gap bugs waiting to happen, not style nits — a dialog dismissed during
  an await can crash or act on a dead context.
- `Share.shareXFiles` in `qr_code_screen.dart:389` is deprecated; `share_plus`
  now wants `SharePlus.instance.share()`. This is on the QR sharing path, which
  is a core flow.
- `withOpacity` deprecations in `verify_email_screen.dart`, `profile_screen.dart`,
  `qr_code_screen.dart` — mechanical, replace with `withValues()`.

Treat the current count as a ratchet: do not increase it.
