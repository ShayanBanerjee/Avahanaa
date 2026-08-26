---
description: Audit the alert-urgency path from push receipt to owner reaction
---

Audit how loudly and reliably an alert actually reaches the owner right now, and
what the next improvement should be.

Read `docs/alert_escalation_options.md` and `docs/known_issues.md` first, then
verify against the real code rather than the docs:

1. **Channel configuration** — `FCMService._criticalChannel` and
   `_legacyChannel`: importance, sound, vibration, category. Note that channel
   settings are immutable after first creation on a device.
2. **The manifest mismatch** — is `default_notification_channel_id` still
   pointing at the legacy channel? What does that do to a system-displayed push?
3. **Payload type** — does the app control presentation (data-only) or does
   Android auto-display it, skipping dedupe and reminders?
4. **Escalation** — reminders at +3 and +15 minutes: are they scheduled from
   `sentAt`, cancelled on read, and restored after process death?
5. **The unused alarm sound** — `assets/audio/avahanaa_alarm.wav` is bundled but
   referenced nowhere, and is in the wrong location for an Android custom
   notification sound.
6. **Silent mode and DND** — what happens today if the phone is on silent?

Report the current worst case: phone in a pocket, on silent, app killed. Then
recommend the single highest-value next change, with its Play Store risk.
