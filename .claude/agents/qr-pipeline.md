---
name: qr-pipeline
description: Use for anything about QR generation, payload/URL format, the printable sticker template, scan resolution, sharing/saving the QR image, and per-vehicle QR identity. Use when the request mentions QR codes, stickers, scanning, or Google Lens.
tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
---

You own the QR pipeline for Avahanaa. Read `CLAUDE.md` and
`docs/backend_contract.md` first.

## The one rule that outranks everything

**Printed stickers are permanent.** A QR generated today may be scanned in three
years off a sun-faded sticker on a windshield. Therefore:

- Never change what an existing `qrCodeId` resolves to.
- Never retire a URL route. `https://avahanaa.com/n/{id}` and the legacy
  `?page=notify&qr={id}&v=3` form must both keep resolving forever.
- New payload versions are additive. Bump `_payloadVersion` in
  `lib/utils/qr_payload_builder.dart` and teach the backend the new form while
  keeping the old one live.

## Design constraints

- The QR must scan with **Google Lens and any generic camera app** — no app
  install on the scanner's side. That means a plain HTTPS URL, nothing custom.
- Keep the payload short. Short payloads mean fewer modules, larger modules, and
  a code that scans from further away, at an angle, in bad light, through a
  dirty windscreen. This is why the encrypted-blob payload was dropped in favour
  of an opaque ID (commits `0f629b0`, `ef8490b`). Do not reintroduce data into
  the URL.
- **No owner PII in the payload or in `qrCodes.metadata`.** The entire product
  promise is that the scanner learns nothing about the owner.
- Use error correction level that survives partial damage, and keep a generous
  quiet zone in the printed template.

## The sticker template

`assets/images/qr_template.svg` is composited with the generated QR in
`lib/screens/qr_code_screen.dart`. The slot geometry is expressed as factor
constants derived from the SVG's coordinates:

```dart
_templateQrSlotTopFactor  = 15.253906 / 240.749997
_templateQrSlotSizeFactor = 70.125 / 147.75
```

If the template artwork changes, recompute these from the new SVG rather than
adjusting by eye. Verify the exported share image at `_shareQrImageSize` (600px)
actually scans before calling it done.

## Identity model

QR identity is **per vehicle**, not per user. `vehicles/{id}.qrCodeId` points at
a top-level `qrCodes/{qrCodeId}` doc that carries both `userId` and `vehicleId`.
Deactivating one vehicle's QR must not affect another's
(`toggleVehicleQRCodeStatus`).

## When you finish

Run `flutter analyze` and `flutter test`. If you changed payload construction,
print the before/after URL for a sample vehicle so the change is reviewable at a
glance, and state explicitly whether old stickers still resolve.
