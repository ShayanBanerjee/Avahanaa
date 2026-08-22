# Google Play compliance notes

Avahanaa is live on Play and has already been through review, including a round
specifically about notification behaviour (commits `fa2ef7f`, `a1ab995`). This
file records what was learned so it is not relearned the hard way.

## Standing constraints

**Notifications.** The app currently ships a high-importance channel with strong
vibration and the default sound, deliberately *without* full-screen intent, to
avoid the declaration requirement. Any change that adds alarm-stream audio, DND
bypass, or full-screen intent is a review-visible change. Read
`docs/alert_escalation_options.md` §Stage 2 first, and ship it in an isolated
release.

**Full-screen intent.** If `USE_FULL_SCREEN_INTENT` is ever added to the
manifest, a Play Console declaration becomes mandatory. For apps targeting
Android 14+ the permission is only default-granted to apps whose core function
is calling or alarms; otherwise the app must request it at runtime and work
without it. Never make the alert path depend on it.

**Data safety form.** The app collects email, an optional phone number, vehicle
registration/colour/model, and an FCM token. The form must match reality. When
you add a field to `users`, `vehicles`, or `notifications`, check whether the
Data Safety declaration still matches before the next upload.

**Privacy policy.** Must be reachable both from the Play listing and in-app.
In-app it lives at `lib/screens/legal_documents_screen.dart`, pointing at
`https://avahanaa.com/privacy-policy.html`. If that URL 404s, review fails.

**Account deletion.** Play requires in-app account deletion *and* a web deletion
route. `AuthService.deleteAccount` handles the in-app side and batch-deletes
vehicles, linked `qrCodes`, and notifications. If you add a new user-owned
collection, add it to that deletion path — an orphaned collection is a policy
problem, not just a bug.

**Ads.** AdMob banners appear on home, notifications, and profile. Ads must not
overlap or be adjacent to interactive controls in a way that causes accidental
clicks, and must not appear on the alert-acknowledgement path — an ad next to
"I'm on my way" during an emergency is both a policy risk and a product failure.
`AdMobBanner` correctly uses test ad units outside release mode; keep that.

**Permissions.** Currently only `VIBRATE` and `POST_NOTIFICATIONS`. Every added
permission needs a justification in the listing. Location, camera, and contacts
are all things this app can be tempted into — each one materially raises review
risk. Prefer designs that do not need them.

**Sensitive-looking features to avoid.** Do not build anything that reads or
looks like it reads other people's vehicle data, surveillance, or number-plate
lookup of vehicles the user does not own. The app previously moved a vehicle
details API key server-side and then dropped the API for a local regex
(`0841853`, `ee0a481`) — that direction was correct; do not reverse it.

## Pre-upload checklist

1. `flutter analyze` clean, `flutter test` green.
2. `version:` bumped in `pubspec.yaml` (Play rejects duplicate version codes).
3. `android/key.properties` present; `flutter build appbundle --release`
   succeeds. Confirm no `*.jks` is staged for commit.
4. Release build smoke-tested on a real device: signup → verify email → add
   vehicle → generate QR → scan it with Google Lens → receive alert →
   tap notification → lands on the right notification.
5. Test with the app **killed**, not just backgrounded. The background handler
   in `main.dart` and the `flutter_local_notifications` path behave differently.
6. Data Safety form still accurate for any new fields.
7. Privacy policy and terms URLs return 200.
8. If notification behaviour changed at all, write the release note explaining
   the user-facing effect, and be ready to justify it.
