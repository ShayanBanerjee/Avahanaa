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

Added Sep 2026, and this batch **does** change the declaration:

- **Purchase history** — new. Collected, not shared, for app functionality;
  required once subscriptions ship.
- **Approximate location** — new, from the person scanning rather than the
  account holder. See the Location note below.
- `users` gained the alert-budget fields and `notifications` gained
  `deliveryTier` and `location`. Everything but `location` is app state rather
  than a new kind of personal data.

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

**Ads — CHANGED Sep 2026.** There is now exactly one banner, in the app shell
above the nav bar, and it disappears for subscribers. The alerts screen has no
banner at all: it is the alert-acknowledgement path, and an ad next to "I'm on
my way" during an emergency is both a policy risk and a product failure.

Rewarded ads were added alongside it (`rewarded_ad_service.dart`). Two things
Play and AdMob both care about:

- **The reward must be disclosed before the ad plays.** The plan screen states
  it — one ad, one alert — and the ad is only ever started by a button labelled
  with what it buys. Never auto-play a rewarded ad, and never present one as
  the price of something the user has already paid for.
- **Test ad units outside release mode, always.** Both `AdMobBanner` and
  `RewardedAdService` branch on `kReleaseMode`. Invalid traffic from a debug
  build gets AdMob accounts suspended, and a suspension takes the banner and
  the rewarded units down together.

`RewardedAdService._liveUnitId` is currently a **placeholder** and must be
replaced with a real unit id before a release build. See
`docs/monetization.md`.

**Subscriptions — NEW Sep 2026, review-visible.** Avahanaa Plus ships three
Google Play subscriptions. Play's subscription policy has specific, enforced
requirements, and the ones this app has to keep meeting:

- **Price, period and renewal stated before purchase**, in the store's own
  localised currency. The plan screen renders `ProductDetails.price` from Play
  and never a hardcoded figure; the fallbacks in `billing_service.dart` are for
  the frame before the store answers and for the store being unreachable.
  Showing a rupee figure to somebody Play is charging in dollars is a violation.
- **A restore path reachable from the UI.** "Restore a previous purchase" on the
  plan screen.
- **`completePurchase` on every purchase, without exception.** Play auto-refunds
  any subscription left unacknowledged for three days, silently.
- **No dark patterns.** The free tier and the ad path are presented as genuine
  alternatives, because they are: three alerts a month covers most owners
  outright. Do not reorder that screen to bury them.

**Metering a safety alert.** The credit system puts a limit on alerts the owner
*receives*, which is the part of this release most likely to draw a question —
from review, from a user, or from a journalist. The answer has to be the same
in all three cases and it has to be true:

- `emergency` is never metered.
- A spent budget produces a quieter alert, never a missing one. The record is
  always written and the push is always sent.
- The person scanning is told nothing about the owner's plan.

`docs/monetization.md` carries the full argument. If any of those three stops
being true, the feature is no longer defensible and should not ship.

**Location — NEW Sep 2026, and it is not the app user's.** The scan page asks
the *person scanning* for their browser location and attaches it to the alert
so the owner knows which of their vehicles is involved and roughly where.

No Android location permission is involved and none should be added — this is
`navigator.geolocation` on the web page, subject to the browser's own prompt.
But the data safety form still has to declare it, and it is worth wording
carefully because the subject is a third party rather than the account holder:
**approximate location, collected, optional, not shared, for app functionality.**

The server rounds to three decimals (~110 m) before storing and never writes the
raw fix. Keep it that way: precise coordinates of an anonymous passer-by,
attached to a record the app then shows to a stranger, is a different product
with a different risk profile.

**Permissions.** Currently `VIBRATE`, `POST_NOTIFICATIONS` and
`USE_FULL_SCREEN_INTENT`. Every added
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
9. Subscriptions: products active in Play Console, the service account granted
   View financial data, RTDN topic wired, AdMob SSV callback URL set. A build
   shipped without these presents as an empty paywall and ads that pay nothing.
   `docs/monetization.md` → "What you have to do".
10. Verify the meter's carve-outs on a real device before upload: a fourth alert
   on a fresh account arrives quietly rather than not at all, and an
   `emergency` at zero balance still alarms.
