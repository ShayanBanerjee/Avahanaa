# Web ↔ backend sync tracker

Audit date: **2026-08-25**. Live host inspected: `https://avahanaa.com`.
Repos compared:

- `Avahanaa` (this repo) — Flutter app, plus a `functions/` + `public/` +
  `firestore.rules` backend added in `79b7720` on 2026-08-25.
- `Avahanaa-Web` (`github.com/ShayanBanerjee/Avahanaa-Web`) — marketing site,
  scan page, and a `notifyOwner` callable. Last commit `3d0c935`, 2025-12-05.

**Both deploy to the same Firebase project, `congestion-free`.** That is the
root of everything below.

## Headline

The scan-to-alert backend in this repo has **never been deployed**. Everything
serving real traffic is the 2025 `Avahanaa-Web` code, and that code reaches the
owner's phone by reading the owner's record — `fcmToken` *and* `phoneNumber` —
straight into an anonymous stranger's browser.

## Evidence

| Probe | Result | Reading |
|---|---|---|
| `GET /` | 200, 88 842 B, `last-modified: 2026-03-02` | Live build is newer than either repo's HEAD — deployed from an uncommitted working tree |
| `GET /api/qr/{id}` | 200 **HTML** | `resolveQr` not routed; catch-all rewrite swallows it |
| `GET /api/notify` | 200 **HTML** | `notify` not routed |
| `GET /api/firebase-config` | 200 **HTML** | `getFirebaseClientConfig` rewrite exists in the web repo but the function is not deployed |
| `…cloudfunctions.net/{resolveQr,notify,deliverAlert}` | 404 (asia-south1 + us-central1) | This repo's functions do not exist in the project |
| `…us-central1…/notifyOwner` | 400 | The **only** deployed function |
| Response headers on `/` | no `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy` | This repo's `headers` block is not live |

Deployed `index.html` (88 842 B) matches neither `Avahanaa-Web/index.html`
(79 969 B) nor this repo's `public/index.html` (11 969 B). Deployed
`notify.html` is 36 302 B against 30 599 B committed. **Live hosting is drifted
from git in both directions — there is no commit that reproduces production.**

## Divergences, by severity

### S1 — Owner PII is exposed to the scanner

The live page, running unauthenticated in the scanner's browser, does its own
Firestore reads (`live index.html`, ~lines 567–844):

```js
const qrDoc   = await db.collection("qrCodes").doc(candidate).get();
const userDoc = await db.collection("users").doc(userId).get();   // ← owner record
owner.fcmToken           = userData.fcmToken.trim();
owner.contact.phoneNumber = userData.phoneNumber;                  // ← owner's phone
await db.collection("users").doc(...).collection("vehicles")...
```

It then hands the harvested token back to the server:

```js
const callable = functionsClient.httpsCallable("notifyOwner");
await callable({ qrId, userId, fcmToken, title, body, metadata });
```

Three separate failures in one flow:

1. **The core product promise is broken.** `CLAUDE.md`: *"No phone number,
   email, or identity is ever revealed to the scanner."* The owner's phone
   number is fetched into the stranger's browser. Whether the UI renders it is
   irrelevant — it is in the page's memory and in the network tab.
2. **Play Data Safety exposure.** This is undisclosed sharing of personal
   contact data with third parties. See `docs/play_store_compliance.md`.
3. **`notifyOwner` trusts a client-supplied `fcmToken` and `userId`.** Anyone
   can call the callable with any token and push an arbitrary
   title/body to that device. There is no rate limit and no QR ownership check.

For the client reads above to succeed, the **deployed** Firestore rules must
allow anonymous reads of `users/{uid}`. This was not verified directly (the
audit's REST probe was sandbox-blocked). **Verify before anything else:**

```bash
firebase firestore:rules get --project congestion-free
```

If those reads are in fact denied, the live scan flow is silently broken
instead — still a defect, a different one.

This repo's `firestore.rules` (never deployed) closes all of it: `users/` is
owner-only, `qrCodes/` is unreadable by clients, `notifications/` create is
`if false`.

### S2 — `notifyOwner` violates the FCM payload contract

Against `docs/critical_notification_payload_contract.md` and
`docs/backend_contract.md`:

| Contract requirement | `notifyOwner` does |
|---|---|
| Prefer **data-only** | Sends a `notification` block → Android auto-displays it in background/terminated state, so `showNotificationForMessage` never runs. **Dedupe and the +3/+15 min escalating reminders are silently dead.** |
| `channel_id: avahanaa_critical_alerts_v2` | Not set → falls to the manifest default `congestion_free_channel`, the quiet legacy channel (known issue #1) |
| `notificationId` = Firestore doc ID, sent in `data` | Not sent at all. Uses `.add()` and never surfaces the ID → the app cannot dedupe, cannot schedule reminders keyed to it, cannot deep-link |
| `type: vehicle_alert` | Sends `source: "avahanaa-web"` instead |
| `sentAt` in data | Absent → app falls back to receipt time, so reminder timing drifts |
| Write `vehicleId` | Absent → the per-vehicle notification index is unusable |
| Rate-limit per `qrCodeId` | None |

The urgency guarantee — the thing `docs/alert_escalation_options.md` calls the
whole product — **does not currently run in production**.

### S3 — `notifyOwner` has a reference bug that masks validation errors

`Avahanaa-Web/functions/index.js:139`:

```js
`Missing required fields ${safeStringify(data, { pretty: true })}: …`
```

`data` is not defined in that scope; the variable is `payload`. Any request
missing a required field hits a `ReferenceError` and returns `internal`
instead of `invalid-argument`, so the page shows a generic failure and the real
cause never reaches the caller.

### S4 — Hosting configs conflict; last deploy wins

| | this repo | `Avahanaa-Web` |
|---|---|---|
| `hosting.public` | `public` | `.` (repo root) |
| rewrites | `/api/qr/**`→`resolveQr`, `/api/notify`→`notify`, `/n/**`→`index.html` | `/api/firebase-config`→fn, `**`→`/index.html` |
| security headers | 3 set | none |
| functions region | `asia-south1` | default `us-central1` |

Deploying either repo silently overwrites the other's hosting config.

> **Do not run `firebase deploy` from this repo as-is.** Its `public/` holds
> only the scan page (`<title>Alert the owner · Avahanaa</title>`, 11 969 B).
> Deploying it replaces the marketing homepage at `avahanaa.com` with a bare
> scan page.

### S5 — Region change costs latency on the alert path

This repo pins `asia-south1` (Mumbai); the deployed function is `us-central1`.
For Bangalore scanners that is roughly a 200 ms round-trip saving per call —
worth having on a path measured in seconds, but it means the two function sets
cannot be swapped in place. `asia-south1` is correct; migrate deliberately.

### S6 — Status vocabulary mismatch (minor)

`notifyOwner` writes `status: "sent"`. This repo's backend uses
`queued` → `delivered` | `undelivered`. `NotificationModel` defaults to
`'sent'` and never branches on the value, so nothing breaks today — but any
future UI that reads `status` will see two vocabularies in one collection.
Existing documents will need a backfill.

## What is already correct

- **QR routing is compatible.** The live page parses both
  `/n/{qrCodeId}` (`parseShortNotifyRoute`) and
  `?page=notify&qr={id}&v=3`, matching `qr_payload_builder.dart`. Printed
  stickers stay valid through any cutover. This constraint is permanent.
- **Legacy AES payloads still decode.** The live page keeps an `AES-CBC` path
  for pre-v3 QRs, mirroring the (dead) `lib/utils/qr_encryption.dart`. Any
  replacement scan page must keep it or old stickers break.
- **This repo's `functions/index.js` is contract-correct**: data-only, right
  channel, `notificationId` = doc ID, dual-window rate limit keyed by QR,
  bounded retry, write-before-push ordering, and dead-token cleanup. It is the
  right target — it is simply not deployed.
- `firestore.indexes.json` here covers the three queries the app actually runs.

## Status — what has been built

Prepared on branch **`feat-secure-scan-backend`** in
`../Avahanaa-Web` (a checkout sits alongside this repo). **Nothing is
deployed.** The runbook is `Avahanaa-Web/DEPLOY.md`.

Decision taken 2026-08-25: `Avahanaa-Web` becomes the single source of truth
for hosting, functions, rules and indexes. The `functions/` + `public/` +
`firestore.rules` tree in *this* repo is superseded and should be deleted once
the deploy lands — leaving it is how the two configs clobber each other.

| # | Item | State |
|---|---|---|
| 1 | Repo reconciled with the deployed bytes (commit `77d9dbc`) | done — the 534-line rollback is averted |
| 2 | Scan page moved off client-side `users` reads | done — zero `collection("users")` calls remain |
| 3 | `resolveQr` / `notify` / `deliverAlert` ported, contract-correct | done |
| 4 | `/api/lookup` — plate search, server-side, IP rate-limited | done, needs backfill (below) |
| 5 | `notifyOwner` reduced to a refusing stub, kept in us-central1 | done |
| 6 | Rules + indexes moved in beside the code they protect | done |
| 7 | One hosting config; security headers restored | done |
| 8 | Duplicate QR resolve on mount coalesced | done — one round trip saved |
| 9 | `licensePlateCanonical` written by the app | done, this repo |
| 9b | `notify.html` — a second live copy of the leak — redirected away | done |
| 10 | Deploy | **not started — yours to run** |
| 11 | Delete `notifyOwner`, ~1 week after deploy | pending |
| 12 | Backfill `status: "sent"` documents | pending, cosmetic |

### Verified

- The rewritten page compiles under Babel and renders; submitting calls
  `GET /api/qr/:id` → `GET /api/lookup?plate=` → `POST /api/notify` with the
  right body shape, and fails gracefully when the backend is absent.
- Coalescing confirmed: two identical `/api/qr` requests on mount became one.
- `node --check` passes on the ported backend; `flutter analyze` stays at zero.
- Every app write to `qrCodes` is a `.doc()` merge-set, so `userId` carries
  through and the stricter rules do not break it.

`notify.html` deserves its own line: it was a standalone second implementation
of the scan flow with its own `users/{uid}` read for `fcmToken` and
`phoneNumber`, and it was live (`GET /notify.html` → 200). It is deleted and
301'd to `/index.html?page=notify`. Worth remembering that the leak existed in
two places — if any other entry point is ever added, it needs the same audit.

### Not verified, and cannot be from here

- **Whether the deployed rules actually permit the anonymous `users` reads.**
  The audit's REST probe was sandbox-blocked. Run
  `firebase firestore:rules get --project congestion-free` before anything
  else — it decides whether this is a live leak or a broken scan flow.
- **That a real phone rings, and that the +3 min reminder fires.** This is the
  regression that matters most and only a physical device proves it.
  `DEPLOY.md` step 5 walks it.

### Carried forward

- **Plate lookup needs a backfill.** It matches
  `metadata.vehicle.licensePlateCanonical`, which existing `qrCodes` documents
  do not have. Vehicles re-saved by an updated app get it; the rest silently
  answer "no vehicle matches". `canonicalisePlate` is duplicated in
  `functions/index.js` and `lib/utils/qr_payload_builder.dart` and the two must
  stay byte-identical.
- **Plate lookup is the softest surface in the system.** A sticker cannot be
  guessed; `KA01AB____` is ten thousand tries. Rate-limited per IP and given an
  off switch (`PLATE_LOOKUP_ENABLED=false`), but kept because production
  already had it. Worth revisiting on its own merits.
- **Legacy stickers have the owner's FCM token printed on them.** The v1/v2
  encrypted payloads embedded it. Those windshields cannot be recalled. The
  page now discards it and the server accepts no client token, so it is
  contained, not fixed — the tokens stay valid until each app rotates them.
- **Watch item:** `FirestoreService.syncQrCodeMetadata`
  (`firestore_service.dart:469`) merge-sets `qrCodes` without `userId`. Fine on
  an existing document; denied if it ever creates one, and the error is
  swallowed by a `debugPrint`.
