# Getting the owner's attention: options, costs, and the recommended path

Researched August 2026. The product requirement: when a stranger scans the
sticker, the owner must *notice* within seconds even if the phone is in a pocket
on silent, and must be able to confirm "I'm coming" back to the scanner.

## Summary of the recommendation

**Do not buy telephony.** Build a **full-screen, call-style alarm notification**
in the app. It is free, unlimited, faster than a phone call, works on a locked
screen, and is exactly the mechanism WhatsApp and every alarm clock app uses.
Reserve real phone calls for a paid tier later, if ever.

The three-stage plan, cheapest and highest-impact first:

| Stage | What | Cost | Effort | Play risk |
|---|---|---|---|---|
| 1 | Alarm-attribute notification channel with `avahanaa_alarm.wav`, bypassing silent mode | ₹0 | Small | Low |
| 2 | Full-screen intent "incoming alert" screen, ringing over the lock screen | ₹0 | Medium | Medium — needs a Play declaration |
| 3 | Actual voice call fallback for non-responders | ~₹0.70–1.50/min | Large | Low |

Stage 1 alone probably closes most of the gap. Stage 2 is what makes it feel
like a phone call. Stage 3 is a business decision, not an engineering one.

---

## Stage 1 — Alarm-grade sound (free, do this first)

Today `assets/audio/avahanaa_alarm.wav` ships in the bundle and is referenced
nowhere. The critical channel `avahanaa_critical_alerts_v2` uses the default
notification sound at `Importance.max`.

What to change:

1. Move the audio to `android/app/src/main/res/raw/avahanaa_alarm.wav` (Android
   custom notification sounds must be a raw resource, not a Flutter asset).
   Keep it under ~10 seconds; Android truncates long notification sounds.
2. Create a **new** channel id — for example `avahanaa_critical_alerts_v3`.
   Channel settings are immutable after first creation on a device; editing the
   existing channel's sound silently does nothing for existing installs. Every
   sound/importance change needs a new id, and the old one should be deleted
   with `deleteNotificationChannel`.
3. On the new channel set:
   - `sound: RawResourceAndroidNotificationSound('avahanaa_alarm')`
   - `audioAttributesUsage: AudioAttributesUsage.alarm` — this is the key line.
     It routes the sound through the **alarm stream**, so it plays at alarm
     volume and is audible when the ringer is on silent or vibrate.
   - `importance: Importance.max`, `category: AndroidNotificationCategory.alarm`
     (already set), `enableVibration`, strong `vibrationPattern` (already set).
4. Ask for the notification-policy exemption only if you also want to pierce Do
   Not Disturb. That is a separate, heavier user grant — treat it as optional
   and never block the app on it.
5. Give users a per-vehicle "alarm sound" toggle in settings and honour it. This
   matters for both Play review and for not being uninstalled.

`flutter_local_notifications` (already a dependency, ^19.5.0) supports all of
the above. No new package needed.

Also fix the manifest mismatch while you are here: `AndroidManifest.xml` sets
`default_notification_channel_id` to `congestion_free_channel`, so any push the
system auto-displays uses the old quiet channel. Point it at the current
critical channel.

## Stage 2 — Full-screen intent (free, needs a Play declaration)

This is what makes the alert behave like an incoming call: the phone rings and a
full-screen "Someone needs you at your vehicle" UI takes over the lock screen,
with Acknowledge / On my way / View details actions.

Mechanics:

- `AndroidNotificationDetails(fullScreenIntent: true, ...)` plus
  `<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />`
  and `WAKE_LOCK` in the manifest.
- `flutter_local_notifications` exposes `requestFullScreenIntentPermission()` on
  the Android plugin for the runtime grant.

**The Play Store catch, and it is the reason this is Stage 2 not Stage 1:**

- Since 31 May 2024 every app declaring `USE_FULL_SCREEN_INTENT` must complete a
  declaration in Play Console describing its core functionality.
- Since 22 January 2025, for apps targeting Android 14+, the permission is
  **granted by default only to apps whose core functionality is calling or
  alarms**. Everything else must prompt the user at runtime and degrade
  gracefully on denial.

Avahanaa is arguably an alarm app — the core function is literally raising an
urgent alarm about the user's own vehicle, and the app is broken without it.
That is a defensible declaration, but it is a judgement call a reviewer makes,
not a guarantee. So:

- Build the full-screen path as an **enhancement layered on Stage 1**, never as
  the only delivery mechanism. If the permission is denied or the declaration is
  rejected, the alarm-sound notification from Stage 1 still fires and the
  product still works.
- Request the runtime permission contextually, with an explanation screen, after
  the user has seen at least one alert — not on first launch.
- Write the Play declaration in terms of alarm functionality on the user's *own*
  vehicle, triggered by a physical QR the user themselves placed. Do not describe
  it as messaging or as third-party-initiated contact.
- Ship it in its own release, so if review pushes back you are not also blocking
  unrelated features.

See `docs/play_store_compliance.md` before submitting.

## Stage 3 — Actual voice calls (paid)

Only worth doing for owners who did not acknowledge within, say, 5 minutes —
i.e. as a paid escalation, not the default path. Indicative India outbound
mobile rates, August 2026:

| Provider | Indicative outbound-to-mobile | Notes |
|---|---|---|
| Twilio | ~₹1.20–1.50/min | Best docs, worst price for India |
| Plivo | from ~₹0.60–0.71/min (SIP), higher on pay-as-you-go | Global, developer-friendly |
| Exotel | ~₹0.80–1.80/min, prepaid credit, per-pulse billing | Strongest India-native support |
| MessageBot / MSG91 | ~₹1.08/min | India SMB-oriented |
| Direct SIP trunk | ~₹0.60–1.20/min | Cheapest, most operational work |

TRAI-regulated termination rates are only ~₹0.30–0.50/min to mobile, so
aggregators are marking up 2–5×. Direct SIP is where the savings are, at the
cost of running your own telephony.

Compliance reality check before anyone builds this:

- Commercial outbound voice in India must run on **TRAI-registered routes** with
  a registered business CLI, and you must retain call records for audit.
- Calls to numbers on the DND/NCPR registry are restricted. An alert about the
  user's own vehicle to a number they themselves registered is consent-based
  rather than promotional, but this needs a real look before launch, not after.
- Billing is per-pulse/per-minute with a minimum, so a 5-second "your car is
  blocking someone" call still costs a full unit. At ₹1/call and 10k alerts a
  month that is ₹10k/month for something a free notification does better.

**Cheaper middle grounds if you want a second channel without voice:**

- **SMS**: ~₹0.12–0.25 per message on Indian transactional routes, ~10× cheaper
  than a call, but requires DLT registration of your sender ID and templates.
  Useful as a "the app didn't get through" fallback when the FCM token is stale.
- **WhatsApp Business API**: utility-template messages are cheap per conversation
  in India and land with a sound users already respond to. Needs a Meta business
  verification and approved templates.
- **A second FCM push to a "someone is waiting" high-priority channel**, plus
  repeat reminders — which the app already does at +3 and +15 minutes. Free.

## Why the free path is genuinely better, not just cheaper

- A push arrives in under a second. A telephony API call takes 5–15 seconds to
  ring, and the owner may decline an unknown number.
- The full-screen intent shows *context* — which vehicle, what reason, a map, a
  photo. A phone call is a voice robot reading a reason code.
- The reply path is in-app. The owner can send "On my way, 3 minutes" back to
  the scan page. A phone call cannot do that without building an IVR.
- Zero marginal cost means you can escalate aggressively — ring again at 1, 3,
  and 10 minutes — which is the actual product goal. Per-minute pricing makes
  you stingy with exactly the thing that makes the product work.

## Acknowledgement loop (the other half, and it is free)

The scanner is standing next to the car with the page open. Close the loop:

- Owner taps "On my way" → write `acknowledgedAt` + an ETA bucket to
  `notifications/{id}` → the still-open scan page updates live via a Firestore
  listener.
- The scanner sees "Owner notified, on the way — ~4 min" and calms down. That
  is the de-escalation the whole product exists to cause, and it costs nothing.
- Track acknowledgement rate and time-to-acknowledge. That is the metric that
  tells you whether Stage 2 or Stage 3 is worth building at all.

## Sources

- [Understanding foreground service and full-screen intent requirements — Play Console Help](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en)
- [Behavior changes: Apps targeting Android 14 or higher — Android Developers](https://developer.android.com/about/versions/14/behavior-changes-14)
- [Full-screen intent limits — Android Open Source Project](https://source.android.com/docs/core/permissions/fsi-limits)
- [flutter_local_notifications — pub.dev](https://pub.dev/packages/flutter_local_notifications)
- [India Voice API Pricing — Plivo](https://www.plivo.com/voice/pricing/in/)
- [Exotel Plans & Pricing 2026 — CloudTalk](https://www.cloudtalk.io/blog/exotel-pricing/)
- [Voice Call API in India 2026: Pricing, Features, Providers — MessageBot](https://messagebot.in/blog/voice-call-api-india/)
- [Plivo vs Exotel vs Ozonetel vs Twilio India 2026 — Caller Digital](https://caller.digital/blog/telephony-partner-voice-ai-india-plivo-exotel-knowlarity-twilio-2026)
