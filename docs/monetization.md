# The alert meter

> Built Sep 2026. Nothing in it is live until the Play Console products exist
> and the `Avahanaa-Web` backend is deployed — see **What you have to do**.

## The deal

| | |
|---|---|
| Free, forever | **3 full-strength alerts per 30 days**, per account |
| Top up with attention | 1 rewarded ad → 1 alert, capped at **12** banked credits |
| Take the meter off | Avahanaa Plus — weekly / monthly / yearly |

Prices in the app are placeholders for one frame. The authoritative figure is
always `ProductDetails.price` from Google Play: it arrives localised and
tax-correct, and showing a hardcoded rupee figure to somebody Play is charging
in another currency is a policy violation as well as a lie. The fallbacks in
`billing_service.dart` are ₹129 / ₹349 / ₹1,999.

## The part that needed an argument

The meter is on alerts the owner **receives**. That is a paywall in front of a
safety notification, and it is worth being honest that this is an unusual thing
to build. Two carve-outs make it defensible, and both are enforced on the
server, not in the app:

1. **An emergency is never metered.** `ALWAYS_FREE_REASONS` in
   `functions/index.js` is checked before the balance is. A fire, a crash or an
   injury rings the phone at full volume whatever the balance says.
2. **Running out never makes an owner uncontactable.** At zero, the alert is
   still written to Firestore and still pushed — as a *quiet notice* rather
   than the alarm. What is withheld is the urgency: the max-importance channel,
   the alarm-stream audio, the full-screen intent, and the +3/+15 minute
   reminders. The alert's own words are kept; the restore prompt never replaces
   them.

Both are single constants (`AlertBudget.emergencyIsAlwaysFree`,
`ALWAYS_FREE_REASONS`, and the `TIER_QUIET` branch). Removing either is a
deliberate act, and `test/alert_wallet_test.dart` and `test/alert_tier_test.dart`
will notice.

A third rule falls out of the privacy promise: **the scanner is told nothing**.
`/api/notify` returns an identical response either way — same status, same body,
same timing. "This owner is out of credits" is exactly the signal somebody with
bad intentions would want, and the state of a stranger's subscription is not a
passer-by's business.

## Where the numbers live

`users/{uid}` carries the wallet, and **every field is server-written**:

```
plan               'free' | 'weekly' | 'monthly' | 'yearly'
planProductId      the Play product id that granted it
planExpiresAt      Timestamp — a hard date, so a missed renewal lapses
planUpdatedAt      Timestamp
alertCredits       int, ad-earned, capped at 12
freeAlertsUsed     int, this cycle
cycleStartedAt     Timestamp, rolls forward lazily on the next alert
lifetimeAlertsReceived, lifetimeAdsWatched
```

`firestore.rules` excludes all of them from the owner's own update allowlist —
a **denylist** rather than an allowlist, because an allowlist would have to
enumerate every field the app already writes and would silently break the next
one added.

Two server-only collections back it:

- `adRewards/{transactionId}` — one settled AdMob callback. Google's transaction
  id is the idempotency key; it retries, and a retry that paid twice would be a
  credit generator.
- `purchaseTokens/{sha256(token)}` — which account claimed a Play purchase, so
  one subscription cannot be shared across accounts.

`planExpiresAt` is a date rather than a boolean on purpose. A stale `true` gives
service away forever if a renewal notification is ever missed; a stale date
simply lapses.

## The credit path, end to end

```
app          RewardedAdService.showAd()
             └─ mints a 128-bit nonce, sets it as SSV customData
                alongside the Firebase uid as SSV userId
Google  ───► GET /api/wallet/ssv?...&signature=...&key_id=...
             └─ ECDSA-SHA256 verified against gstatic.com/admob/reward/
                verifier-keys.json, over the RAW query string up to
                "&signature=" — rebuilt-from-parsed params will never verify
             └─ adRewards/{transaction_id} written, alertCredits incremented
app          POST /api/wallet/claim {rewardToken}
             └─ polls three times over ~4s: "has my nonce settled?"
             └─ the balance on screen ticks up from the Firestore stream
```

The app never grants a credit. It cannot: it runs on the user's phone, and a
phone can be made to claim anything. The claim endpoint is a read.

## The subscription path

```
app          in_app_purchase → Google Play sheet → purchaseStream
app          POST /api/billing/verify {productId, purchaseToken}
backend      androidpublisher purchases.subscriptionsv2.get
             └─ ACTIVE or IN_GRACE_PERIOD → writes plan + planExpiresAt
Play    ───► Pub/Sub topic play-billing-rtdn → playNotifications
             └─ re-reads the current state and rewrites the grant
```

Renewals never come through the app — a subscription that renews at 3am has to
extend on a phone that is switched off. RTDN handles every event type the same
way: take the purchase token, ask Play what is true now, rewrite. Trusting the
notification's own type field would mean getting a dozen event types and their
out-of-order arrivals right; re-reading the truth is one code path.

`completePurchase` is called on every purchase without exception. **Play
auto-refunds any subscription left unacknowledged for three days**, silently —
the user keeps the app, loses the charge, and you find out by email.

Grace period counts as entitled. Somebody whose card failed is being retried by
Google, and cutting them off instantly turns a payment hiccup into a
cancellation.

## What you have to do

None of this is code, and none of it can be done from here.

### 1. Play Console — create the subscriptions

Monetise → Subscriptions. Product IDs must match exactly:

| Product ID | Billing period |
|---|---|
| `avahanaa_plus_weekly` | 1 week |
| `avahanaa_plus_monthly` | 1 month |
| `avahanaa_plus_yearly` | 1 year |

They must be **active** and the build must be signed with the upload key, or
`queryProductDetails` returns them in `notFoundIDs` and the paywall renders
empty with no error. `billing_service.dart` logs that case loudly.

### 2. Play Console — let the backend verify purchases

Users & permissions → grant the Cloud Functions service account
(`congestion-free@appspot.gserviceaccount.com`) **View financial data**. Without
it, `purchases.subscriptionsv2.get` answers 401 and every purchase fails to
activate. This is the single most common way this feature is broken in
production.

### 3. Play Console — real-time developer notifications

Monetise → Monetisation setup → RTDN. Topic name: `play-billing-rtdn`, in the
`congestion-free` project. Create the Pub/Sub topic first and grant
`google-play-developer-notifications@system.gserviceaccount.com` the Publisher
role on it.

### 4. AdMob — the rewarded unit and its SSV callback

Create a rewarded ad unit and put its id in `RewardedAdService._liveUnitId`
(the placeholder there is not a real unit). Then, on that unit: Server-side
verification → callback URL:

```
https://avahanaa.com/api/wallet/ssv
```

Until this is set, ads play and no credit is ever granted — the app's claim
poll will simply never settle, which by design is silent rather than an error.

### 5. Data safety

The Play data safety form needs updating for the new collection:

- **Purchase history** — collected, not shared, for app functionality. Required
  for subscriptions.
- **Approximate location** — collected *from the person scanning*, optional,
  not shared, for app functionality. See `docs/play_store_compliance.md`; this
  one is worth wording carefully because the subject is not the app's user.

### 6. Test before shipping

License-test accounts (Play Console → Setup → License testing) get real
purchase flows without charges, including a compressed renewal clock. Test at
minimum: a purchase, a cancellation, and a restore on a second device.

## Things deliberately not built

- **No trial.** A free tier that already gives three alerts a month is the
  trial, and stacking a second one produces two expiry dates to explain.
- **No one-off credit packs.** Cash for credits is a worse deal for the user
  than the weekly subscription at every quantity that matters, and offering a
  worse deal beside a better one is a dark pattern even when nobody takes it.
- **No metering of the reply channel.** An owner whose budget is spent can still
  tell the person at their car that they are on the way. That is the half of
  the product that de-escalates the moment, it costs one Firestore write, and
  metering it would be metering the wrong thing entirely.
