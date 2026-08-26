# Google Play compliance notes

Avahanaa is live on Play and has already been through review, including a round
specifically about notification behaviour (commits `fa2ef7f`, `a1ab995`). This
file records what was learned so it is not relearned the hard way.

## Standing constraints

**Notifications — CHANGED Aug 2026, NOT YET SUBMITTED.** The app now ships
`avahanaa_critical_alerts_v3`: max importance, `avahanaa_alarm.wav` on the
**alarm stream** (`AudioAttributesUsage.alarm`), and **full-screen intent**.
Both were previously avoided precisely to dodge the declaration requirement, so
this is a review-visible change and it has not been through review yet.

Before the next upload:

1. **Complete the full-screen-intent declaration in Play Console.** It is
   mandatory once `USE_FULL_SCREEN_INTENT` is in the manifest, and it is.
2. **Ship this in an isolated release.** If review pushes back, the thing to
   argue is the product: an alert that arrives silently is worthless when
   somebody is standing next to the vehicle. If that fails, the fallback is to
   drop FSI and keep the alarm channel — they are independent.
3. DND bypass is still **not** requested. Leave it that way.

What has not changed: the alert path does not depend on FSI. The permission is
requested at runtime and a refusal is expected — the same notification still
arrives as a heads-up on a max-importance channel, which is exactly what
shipped before. On Android 14+ the permission is only default-granted to apps
whose core function is calling or alarms, and Avahanaa is neither.

The manifest's `default_notification_channel_id` was also corrected from the
legacy `congestion_free_channel` to the v3 channel (known issue #1). A
notification-payload push handled by the system used to land on the quiet
legacy channel.

**Full-screen intent.** If `USE_FULL_SCREEN_INTENT` is ever added to the
manifest, a Play Console declaration becomes mandatory. For apps targeting
Android 14+ the permission is only default-granted to apps whose core function
is calling or alarms; otherwise the app must request it at runtime and work
without it. Never make the alert path depend on it.

**Data safety form.** The app collects email, an optional phone number, vehicle
registration/colour/model, and an FCM token. The form must match reality. When
you add a field to `users`, `vehicles`, or `notifications`, check whether the
Data Safety declaration still matches before the next upload.

Added Aug 2026 and worth a look before submitting: `notifications` gained
`acknowledgedAt`, `acknowledgementEta` and `statusToken`, and
`qrCodes.metadata.vehicle` gained `licensePlateCanonical`. None of it is new
*kinds* of data — the reply fields are the owner's own action and the canonical
plate is a normalised copy of a plate already declared — so the existing
declaration should still hold. Confirm rather than assume.

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
