# Known issues and open threads

Ordered roughly by risk. Update this file when one is closed.

## 1. Manifest default channel — CLOSED (Aug 2026)

The manifest pointed `default_notification_channel_id` at the legacy
`congestion_free_channel`, so any push carrying a `notification` block — which
the system auto-displays in background/terminated state — landed on the quiet
channel rather than the max-importance one.

Now points at `avahanaa_critical_alerts_v3`. Both halves of the original fix are
in place: the sender emits data-only pushes (`Avahanaa-Web/functions/index.js`),
*and* the manifest default is correct for anything that slips through.

## 2b. Legacy sticker artwork is bundled but unused (Aug 2026)

`assets/images/qr_template.svg` (230KB) was the old composited sticker. The
sticker is now drawn on a canvas by `lib/utils/sticker_renderer.dart`, and
nothing references the SVG. The `flutter_svg` dependency was removed with it.

The file is deliberately left in place rather than deleted — it is the owner's
artwork and restoring the old design should stay a one-line decision. If it is
not coming back, delete it and the app bundle drops 230KB.

## 2. The alarm asset is unused — CLOSED (Aug 2026)

`avahanaa_alarm.wav` shipped for months referenced by nothing. It is now the
sound of `avahanaa_critical_alerts_v3`, on the **alarm stream**, copied to
`android/app/src/main/res/raw/` — Android will not take a notification sound
from Flutter assets.

Verified on device via `dumpsys notification`:
`mSound=android.resource://com.avahanaa.congestion_free/raw/avahanaa_alarm`,
`usage=USAGE_ALARM`, `mImportance=5`.

Full-screen intent shipped alongside it. **Neither has been through Play review
yet** and both are review-visible — see `docs/play_store_compliance.md` before
the next upload. The copy in `assets/audio/` is now redundant; it is left in
place because deleting it is a separate decision from wiring it up.

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

## 4. Firestore rules and indexes exist here but are NOT deployed — SUPERSEDED (Aug 2026)

`firestore.rules` and `firestore.indexes.json` landed in `79b7720`, and
`firebase.json` now wires both. So the original complaint — nothing in the repo
— is closed.

What replaced it is worse. **Neither file has been deployed**, and the rules
actually live in the project appear to allow an anonymous scan page to read
`users/{uid}` — including `fcmToken` and `phoneNumber`. Production is still
served by the 2025 `Avahanaa-Web` code.

Full audit, evidence and remediation order: `docs/web_backend_sync.md`. That is
now the highest-severity item in the repo.

Indexes needed by existing queries (all three present in
`firestore.indexes.json`, none confirmed live):
- `notifications(userId ASC, sentAt DESC)`
- `notifications(userId ASC, read ASC)`
- `notifications(userId ASC, vehicleId ASC, sentAt DESC)` — used by
  `streamVehicleNotifications`

## 5. Unbounded reads in notification counters — PARTLY CLOSED (Sep 2026)

`streamUnreadNotificationCount` no longer opens its own query. It is derived
from `streamUserNotifications`, which is already live, already capped at 50 and
already in memory — the separate `where('read', false)` listener was a second
billed sync of substantially the same documents to answer a question the first
one had already answered. The count is `.distinct()`, so the badge does not
rebuild when an unrelated field changes.

One behavioural difference: an owner with more than 50 unread alerts sees 50.
The badge caps at 99+ anyway, and that situation means something has gone badly
wrong regardless.

Still open: `getUnreadNotificationCount` and `getNotificationStats` are one-shot
`.get()`s that fetch whole result sets and call `.length`. They should be
aggregate `count()` queries.

## 5b. Screens shared four listeners on one document — CLOSED (Sep 2026)

The shell keeps all three tabs alive in an `IndexedStack`, so every tab's
`StreamBuilder` is mounted at once. That meant **four** live listeners on
`users/{uid}` (the home tab's profile and wallet streams, and the profile tab's
two), two on the vehicles subcollection, and three on `notifications` — each one
its own socket target, its own billed sync and its own rebuild cascade.

`FirestoreService` now memoises them in a `_SharedStream` that retains the last
value and replays it to each new subscriber, because a late subscriber to a
plain broadcast stream sees nothing until the next snapshot — which on a
document that changes a few times a month is a profile tab that renders empty.

The source subscriptions are deliberately never torn down; they are dropped
wholesale by `FirestoreService.disposeSharedStreams()`, called from both
`AuthService.signOut` and `deleteAccount`. **If a third sign-out path is ever
added, it has to call it too** — a listener left open against rules that now
deny it produces a stream of permission-denied errors attributed to a user who
is no longer there.

## 5c. One ad slot, not three — CLOSED (Sep 2026)

`AdMobBanner` was mounted in all three tabs. Because the tabs stay alive, that
was three simultaneous ad loads and three WebViews for one visible strip. The
shell now owns the single instance, above the nav bar.

The alerts screen lost its banner entirely and is not getting it back: it is a
panic surface, and the design system's brief for those is one unmistakable
action with nothing competing.

## 5d. The meter is a paywall in front of a safety alert — BY DESIGN, watch it

`docs/monetization.md` is the argument. In short: `emergency` is never metered,
and a spent budget produces a *quiet* alert rather than a missing one — the
document is always written and the push is always sent.

Both carve-outs are single constants (`AlertBudget.emergencyIsAlwaysFree` in the
app, `ALWAYS_FREE_REASONS` and the `TIER_QUIET` branch in the backend). They are
the whole reason this feature is defensible, and `test/alert_wallet_test.dart`
and `test/alert_tier_test.dart` exist to make removing one noisy.

Two things to watch:

- **The app and the backend each hold a copy of the budget numbers.** The
  server's is authoritative; the app's exists so the UI can render a balance
  without a round trip. If they drift, the app shows a wrong number and the
  server still does the right thing — the correct direction to drift in, but
  worth catching.
- **`RewardedAdService._liveUnitId` is a placeholder**, not a real AdMob unit.
  Release builds will fail to fill until it is replaced. See
  `docs/monetization.md`, "What you have to do".

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

## 8. Analyzer baseline is zero — treat any lint as a regression

`flutter analyze` reports no errors, no warnings and no lints. It did not
always: the baseline was 20 info-level issues, including
`use_build_context_synchronously` clusters that were genuine async-gap bugs and
a deprecated `Share.shareXFiles` call on the QR sharing path. Those were
cleared during the v1.1.0 UI rebuild.

The count is now a ratchet at zero. A single new info-level lint is a
regression, not a rounding error.

## 9. Changing paper inside the Android print dialog wedges the preview

`printing` 5.14.3 forwards Android's `PrintDocumentAdapter.onLayout` to Dart
exactly once, when the job starts. Changing the paper size or the orientation
inside the system print dialog never reaches the Dart callback, so no new
document is produced and the spooler sits on "Preparing preview…"
indefinitely. Reproduced on an API 37 emulator: the first layout logs start and
completion, the second never fires at all.

The app works around it rather than fixing it, because it cannot be fixed from
this side:

- The sticker studio owns paper size and copies-per-sheet, with a live page
  preview built from the same `SheetPlan` the PDF uses.
- `printStickerSheet` passes `dynamicLayout: false`, declaring the document
  fixed for the format it was handed.

Upgrading the plugin is currently blocked: `printing` 5.15.0 depends on
`pdf ^3.13.0` → `xml ^7.0.1`, which conflicts with
`flutter_local_notifications ^19.5.0`. That package carries the alert
escalation path, so it wins. Revisit when `flutter_local_notifications` moves
to `xml ^7`.
