---
name: avahanaa-design-system
description: Avahanaa's visual language and UI patterns — colour tokens, type scale, spacing, component recipes, and the calm-vs-panic design principle. Use when building or restyling any screen, widget, or the printable QR sticker in this Flutter app.
---

# Avahanaa design system

## The governing principle: calm mode vs panic mode

Every surface belongs to one of two modes. Decide which before you design it.

**Calm mode** — onboarding, adding a vehicle, generating a QR, profile,
settings. The user is at home with time. Rich cards, generous whitespace,
supporting copy, illustrations.

**Panic mode** — an alert arrived, the owner is walking fast toward their car,
one-handed, maybe at night, maybe already anxious. Everything is oversized,
maximum contrast, one unmistakable primary action. No decoration, no ads, no
secondary choices competing for attention. If the user has to read a sentence to
know what to tap, it is wrong.

Screens that serve both moments must be designed for panic first.

## Colour tokens

| Token | Hex | Use |
|---|---|---|
| Primary | `#2563EB` | Buttons, links, active nav, focus rings |
| Success | `#10B981` | Confirmations, active QR state, "on my way" |
| Alert | `#DC2626` | Alert notifications, unread badges, destructive actions |
| Alert deep | `#B91C1C` | Escalated reminder alerts |
| Background | `#F9FAFB` | Scaffold background |
| Surface | `#FFFFFF` | Cards, app bar, inputs |
| Info surface | `#F0F9FF` | Informational cards (the QR screen tip card) |
| Text primary | `#1F2937` | Headings and body |
| Border | `#E5E7EB` | Input borders, dividers |

The splash and hero gradient runs `#2563EB` → `#10B981`, top-left to
bottom-right.

Red is reserved. It means "an alert" or "this destroys data" and nothing else —
do not use it for emphasis.

## Shape and spacing

- Radius: **12** inputs and buttons, **16** cards, **24** hero surfaces and the
  QR container.
- Card elevation is **0**. Depth comes from a soft shadow
  (`black.withOpacity(0.1)`, blur 20, offset `(0, 10)`) on hero surfaces only.
- Padding: 16 standard, 24 section, 32 hero.
- Spacing steps: 8 / 12 / 16 / 24 / 32.
- Button padding: horizontal 24, vertical 16.

## Type

Font family `SF Pro Display`, falling back to the platform default.

- App bar title: 18 / w600
- Section heading: 16 / w600
- Body: 14 / regular
- Caption and badge: 10–12
- License plate: 16 / w600 with `letterSpacing: 1.2` — plates always render
  monospaced-feeling and uppercase.

Panic-mode text starts at 24 and goes up. There is no upper bound.

## Component recipes

**Card** — white, radius 16, elevation 0, padding 16. Icon in a tinted circle on
the left, title/subtitle stacked, chevron or action on the right.

**Primary button** — filled `#2563EB`, white text, radius 12, elevation 0,
16/w600. One per screen.

**Input** — filled white, radius 12, 2px `#E5E7EB` border, `#2563EB` when
focused, `#DC2626` on error, content padding 16.

**Unread badge** — `#DC2626` pill, white 10/bold text, `99+` cap, offset
`right: -8, top: -6` on the nav icon.

**Empty state** — muted icon, a heading that says what is missing, a sentence
explaining why it matters, and the action that fixes it. Never a bare blank box.

**QR hero** — white container, radius 24, padding 32, soft shadow, QR centred,
plate below in letter-spaced w600, vehicle descriptor below that in muted text.

## The printable sticker

`assets/images/qr_template.svg` is the sticker artwork; the generated QR is
composited into a slot whose geometry is expressed as factors of the template
dimensions in `qr_code_screen.dart`. If the artwork changes, recompute those
factors from the SVG coordinates rather than adjusting them by eye.

Sticker-specific rules, all of which trump aesthetics:

- Maximum quiet zone around the QR. A cramped code fails on a dirty windscreen.
- High contrast only — pure black on pure white. No gradients, no brand colour,
  no logo overlaying the code.
- The instruction text must read at arm's length through glass: large, short,
  and in both English and Kannada where space allows, since this ships in
  Bangalore.
- Always verify a changed template by scanning the exported 600px image with
  Google Lens before shipping.

## Accessibility

- Minimum tap target 48x48.
- Body contrast at least 4.5:1.
- Test every screen at 320dp width and 2.0x text scale — `qr_code_screen.dart`
  and `profile_screen.dart` have both had overflow regressions.
- Never encode meaning in colour alone; pair the alert red with an icon and a
  label.
