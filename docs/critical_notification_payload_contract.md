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

## Android delivery configuration

When sending through FCM HTTP v1, use high-priority delivery and avoid
collapsing distinct alerts.

- `android.priority`: `HIGH`
- `android.notification.channel_id`: `avahanaa_critical_alerts_v2`
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
