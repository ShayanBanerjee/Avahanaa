# Critical Notification Payload Contract (v1)

This project does not contain the backend sender, but mobile clients now
expect a stable payload contract for critical vehicle alerts.

## Required FCM `data` keys

All alert pushes should include:

- `type`: must be `vehicle_alert`
- `notificationId`: stable unique ID matching Firestore notification document ID
- `title`: short alert title
- `body`: alert message body
- `reason`: alert reason code (for example `emergency`, `blocking_traffic`)
- `sentAt`: UTC timestamp (ISO-8601 preferred)

Optional:

- `vehicleId`, `qrCodeId`: which vehicle and which sticker. Empty strings when
  unknown.
- `tier`: `full` or `quiet`. Added Sep 2026 with the alert budget — see
  `docs/monetization.md`.

  `full` is the alarm: max-importance channel, alarm-stream audio, full-screen
  intent, and the +3/+15 minute escalating reminders. `quiet` is the same alert
  on a default-importance channel with none of that.

  **An absent or unrecognised `tier` means `full`.** Every push from a sender
  older than this feature has no such key, and a default that downgraded them
  would silently un-alarm the entire installed base. `AlertTier.parse` fails
  towards the alarm in every case, and `test/alert_tier_test.dart` holds it
  there.

## Android delivery configuration

When sending through FCM HTTP v1, use high-priority delivery and avoid
collapsing distinct alerts.

- `android.notification.channel_id`: `avahanaa_critical_alerts_v3` for `full`,
  `avahanaa_quiet_notices_v1` for `quiet`.

  `_v3` rather than `_v2` since the alarm sound shipped: a channel's importance
  and tone are frozen the moment Android creates it, so changing how an alert
  sounds requires a new id. `_v2` is still created by the app so that
  notifications already posted on it can be cancelled, and nothing new should
  be sent there.

  Note this only matters for pushes that carry a `notification` block. Data-only
  pushes — which is what the contract asks for — are placed on a channel by the
  app itself, which is precisely how the manifest's stale
  `default_notification_channel_id` was routed around.

- `android.priority`: `HIGH` **for both tiers**. Quiet means it does not alarm,
  not that it arrives late; `normal` priority lets Doze hold a push until the
  next maintenance window, which on an idle phone overnight is hours.
- `android.collapse_key`: omit for unique alerts or set unique per alert

## Compatibility

- Keep existing legacy keys if older clients rely on them.
- Add new keys in an additive way.
- `notificationId` should always resolve to the same logical alert across
  retries/duplicates.

## Retry guidance

For transient failures (5xx, timeout, `UNAVAILABLE`) retry with bounded backoff:

- attempt 1: immediate
- attempt 2: +2 seconds
- attempt 3: +6 seconds
- attempt 4: +15 seconds (final)

Do not mutate `notificationId` between retries.
