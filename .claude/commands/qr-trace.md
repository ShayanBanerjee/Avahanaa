---
description: Trace the full QR lifecycle from generation to alert delivery
---

Trace one QR code end to end through the current code and report where it can
break. Read the actual files; do not work from memory or from the docs alone.

Follow the chain:

1. **Creation** — `FirestoreService.ensureVehicleQrCode`: what document is
   written, what `qrCodeId` is assigned, what legacy fields are dual-written.
2. **Payload** — `QrPayloadBuilder`: the exact URL produced for a sample
   vehicle, both the short route and the query fallback.
3. **Render and print** — `qr_code_screen.dart`: SVG template composition, slot
   geometry factors, share/save export at 600px.
4. **Scan** — what the out-of-repo page at `avahanaa.com` must do with the URL
   (`docs/backend_contract.md`), including the `isActive` gate.
5. **Alert write and send** — the `notifications` doc and the FCM data payload
   (`docs/critical_notification_payload_contract.md`).
6. **Receipt** — `main.dart` background handler → `FCMService` dedupe →
   immediate notification → reminders at +3/+15 → cancellation on read.

For each hop state what would happen if it failed, and flag any place where a
change would break QR codes that are **already printed and glued to
windshields** — those URLs are permanent.

Print the sample URL for a concrete vehicle so the current format is visible.
