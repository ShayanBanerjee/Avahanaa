# Contract with the out-of-repo backend

> **Status (Sep 2026): production still does not honour this contract.** The deployed
> sender is `notifyOwner` from `Avahanaa-Web`, which sends a `notification`
> block instead of data-only, omits `notificationId` and `sentAt`, and does not
> set the alert channel — so dedupe and the +3/+15 min escalating reminders
> never run. See `docs/web_backend_sync.md`. The spec below is still the
> target; `functions/index.js` in this repo implements it correctly but is not
> deployed.

The scan page and the FCM sender are **not in this repository**. They live at
`avahanaa.com` (Firebase Hosting + Cloud Functions). This file is the
app-side view of that boundary. Changing anything here means coordinating two
deploys, and old app versions stay installed for months.

## What the app produces

**QR payload URL** — built by `lib/utils/qr_payload_builder.dart`:

- Primary (short route): `https://avahanaa.com/n/{qrCodeId}`
- Fallback: `https://avahanaa.com/index.html?page=notify&qr={qrCodeId}&v=3`

Both forms must keep working. Stickers already printed and glued to windshields
encode whatever URL was current when they were generated — **QR URLs are
effectively permanent**. Never retire a route; add new ones.

Host/path/prefix are overridable at build time via `--dart-define`:
`QR_REDIRECT_HOST`, `QR_REDIRECT_PATH`, `QR_SHORT_ROUTE_PREFIX`,
`QR_USE_SHORT_ROUTE`.

**`qrCodes/{qrCodeId}` document** — written by
`FirestoreService.ensureVehicleQrCode` / `syncVehicleQrMetadata`:

```json
{
  "userId": "...", "vehicleId": "...", "isActive": true,
  "payloadVersion": "3",
  "payload": "https://avahanaa.com/n/qr_xyz",
  "metadata": {
    "payloadVersion": "3",
    "vehicle": { "color": "White", "carModel": "Honda City", "licensePlate": "KA01AB1234" }
  }
}
```

`metadata` intentionally carries **no owner contact information**. If the scan
page ever needs more, add vehicle-scoped fields only.

## What the backend must do

1. Resolve `qrCodeId` → `qrCodes/{qrCodeId}`. Reject if missing or
   `isActive != true` (that is the user's off switch — honour it).
2. Read `userId` and `vehicleId` from the QR doc, never from the URL.
3. Write `notifications/{notificationId}` with `qrCodeId`, `userId`,
   `vehicleId`, `reason`, `message`, `status`, `read: false`, `sentAt`.
4. Send FCM to `users/{userId}.fcmToken` with the data keys defined in
   `docs/critical_notification_payload_contract.md`. `notificationId` **must**
   equal the Firestore document ID — the app's dedupe, reminder scheduling, and
   deep-link all key off it.
5. Rate-limit per `qrCodeId`. An unauthenticated endpoint that fires a
   max-importance alarm on a stranger's phone is an abuse vector; a single
   scanner should not be able to ring the owner fifty times.

## Reason codes

The app renders these and only these
(`lib/models/notification_model.dart`, `FCMService._titleFromReason`):

`blocking_driveway`, `illegal_parking`, `blocking_traffic`, `double_parked`,
`emergency`, `private_property`, `other`

Unknown codes fall back to a generic title. Adding a code is safe; the app
degrades gracefully. Removing or renaming one is not.

## Delivery requirements

- `android.priority: HIGH`
- `android.notification.channel_id: avahanaa_critical_alerts_v3` (`_v2` is the
  pre-alarm channel and is kept only so old notifications can be cancelled)
- No shared `collapse_key` — distinct alerts must not collapse into one.
- Prefer **data-only** payloads. When a push carries a `notification` block, the
  system displays it directly in background/terminated state and the app's
  dedupe + escalating reminders never run (`main.dart` background handler).

## The reply channel (built Aug 2026)

The owner answers, and the person still standing at the vehicle sees it. This
is the half that de-escalates the moment, and it is the reason the alert was
worth delivering fast.

**Model** — `notifications/{id}` carries:

- `acknowledgedAt` — when the owner replied, null until they do.
- `acknowledgementEta` — which reply, as an id from `lib/models/alert_reply.dart`:
  `omw_now`, `omw_5`, `omw_15`, `cannot_come`, `seen`. Never rename one; old
  app versions stay installed.
- `statusToken` — minted by `notify`, handed once to the scan page. Server-only:
  the rules exclude it from the owner's update allowlist, because an owner who
  could rewrite it could silently cut off the person waiting at their vehicle.

**Endpoints**

- `POST /api/notify` returns `{ok, notificationId, statusToken}`.
- `GET /api/status?id=&t=` returns `{delivered, acknowledged, reply}`, where
  `reply` is `{id, label, onTheWay, at}` or null. Requires the token, compared
  in constant time, and answers 404 identically for a bad token and a missing
  alert so it cannot be walked. Returns nothing about the owner.

**Why polling, not a listener.** The original sketch in
`docs/alert_escalation_options.md` said the scan page would watch Firestore
directly. It cannot any more, and should not: the rules now refuse anonymous
reads, which is exactly what stopped the page harvesting `fcmToken` and
`phoneNumber`. The page polls `/api/status` every 4s, stops on the first reply,
and gives up after ten minutes.

**Keeping the two sides honest.** `REPLY_LABELS` and `REPLY_ON_THE_WAY` in the
backend must match `AlertReply`. `test/alert_reply_test.dart` reads the backend
source and fails if they drift, when both repos are checked out side by side.

## The alert budget (built Sep 2026)

`/api/notify` now spends one alert against the owner's budget before writing,
and records the outcome on the notification document as
`deliveryTier: "full" | "quiet"` plus a `deliveryTierReason` for support. The
push carries the same value in its `tier` data key.

Three invariants, all enforced server-side:

- `emergency` is never metered.
- A spent budget produces a **quiet** alert, never a missing one. The document
  is always written and the push is always sent.
- The scanner is told nothing — identical status, body and timing either way.

Full detail, including the Play Console and AdMob setup that has to happen
before any of it works, is `docs/monetization.md`.

### Endpoints added alongside it

All four are on the same host and take a Firebase ID token in
`Authorization: Bearer`, except the SSV callback which Google signs instead.

| Endpoint | Who calls it | What it does |
|---|---|---|
| `GET /api/wallet/ssv` | Google (AdMob) | ECDSA-verified reward callback; the only thing that grants a credit |
| `POST /api/wallet/claim` | the app | "has my reward settled?" — a read, answering `{settled, credits}` |
| `POST /api/billing/verify` | the app | hands a Play purchase token over for server-side verification |
| `POST /api/alerts/test` | the app | fires a real alert at the caller's own phone; never metered |

`playNotifications` consumes Play's RTDN Pub/Sub topic for renewals and
cancellations. It is not an HTTP endpoint.

## Scan location (built Sep 2026)

`/api/notify` accepts an optional `location: {lat, lng, accuracyM}`. The scan
page asks the browser for it *after* the reason has been chosen, so nobody is
prompted before they know what they are sending, and gives up after six seconds
so an ignored prompt never delays the alert.

**The server rounds to three decimal places — about 110 m — before storing, and
the raw fix is never written down.** That is enough for an owner to work out
which of their parked cars this is, and not enough to follow the person who
scanned it. The asymmetry is the point: this product's whole premise is that
the scanner gives up nothing, and attaching their exact coordinates to the
alert would quietly reverse that.

Stored on the notification document as `location: {lat, lng, accuracyM,
capturedAt}`, or `null` when it was declined or unavailable — which is most of
the time. The app renders it as an optional card
(`lib/widgets/scan_location_card.dart`) and every surface works without it.

The app floors the *displayed* accuracy at 110 m. A browser claiming 8 m is
describing a precision that was thrown away before storage, and repeating it
would be a lie told by rounding.

## Fields the app would like next

Not yet implemented on either side; listed so both sides build the same thing:
- `photoUrl` — scanner-supplied photo of the situation. Needs Storage rules and
  an abuse story before it ships.
