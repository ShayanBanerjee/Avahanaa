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
| Primary | `#1F4FB8` | Buttons, links, active nav, focus rings |
| Success | `#10B981` | Confirmations, active QR state, "on my way" |
| Alert | `#C81B30` | Alert notifications, unread badges, destructive actions |
| Alert deep | `#A01625` | Escalated reminder alerts |
| Background | `#F8FAFC` | Scaffold background |
| Surface | `#FFFFFF` | Cards, app bar, inputs |
| Info surface | `#F0F9FF` | Informational cards (the QR screen tip card) |
| Text primary | `#0F172A` | Headings and body |
| Text secondary | `#475569` | Supporting copy — 7.58:1 on white |
| Text tertiary | `#64748B` | Overlines, captions — still has to clear AA |
| Border | `#E2E8F0` | Input borders, dividers |

The splash and hero gradient runs `#1F4FB8` → `#0E5E52`, top-left to
bottom-right — anodised steel-blue into deep teal.

Deepened in Aug 2026. The previous `#2563EB` → `#10B981` is the most generic
gradient on the internet; every generated landing page has it, and it made a
shipped product look like a template. Same hue journey, half the shouting, and
the worst ramp stop improved from 4.62:1 to 5.78:1 against white as a side
effect.

**The neutrals are slate, not grey.** They carry a few degrees of the brand's
blue. Pure grey beside a saturated blue reads as two palettes that happened to
meet — the grey looks faintly green by comparison. This is also where the
contrast came from: secondary text moved from 4.83:1 to 7.58:1 on white, and
the old tertiary was failing AA outright at 2.54:1.

**The alert red is a crimson, not a fire-engine red.** `#DC2626` is the most
default-looking colour on a phone, and at panic-card size it filled a third of
the screen looking like a stock error dialog. Rotated toward blue and dropped
in value, it stays just as alarming and every ramp stop gained contrast.

Red is reserved. It means "an alert" or "this destroys data" and nothing else —
do not use it for emphasis.

**Green is reserved too**, and it is the one that keeps slipping. It means a
*status*: the QR is live, protection is on, the owner replied. It is not
decoration. The QR reticle used to be drawn in it — the brackets are a scanner
affordance ("point a camera here"), not a readout, and spending the confirmation
colour on them put a third saturated hue on a screen that is otherwise graphite
and bronze. They are bronze now. Before reaching for green, check whether the
thing is reporting a state or just wants to look lively.

## The metallic layer

Surfaces are machined, not flat. Three things do the work, in
`lib/widgets/metal.dart`:

1. **An asymmetric five-stop ramp** (`MetalPalette`). Even two-stop gradients
   read as plastic; real metal has a bright band and a fast falloff, so the
   stops are deliberately uneven (`0.0, 0.28, 0.52, 0.82, 1.0`).
2. **A bevel.** One hairline of white on the top edge, one of black on the
   bottom.
3. **A sheen that moves** (`SheenSweep`) — a specular band crossing once on
   entrance, then every ~9s. Continuous shimmer stops reading as premium and
   starts reading as a loading state, so the pause is the point.

Palettes: `brand` (hero surfaces, primary buttons), `slate` (every ordinary
card — near-flat on purpose, so light falls the same way across the whole app
rather than on five special cases), `alert` (panic banner),
`success` (verify email), `graphite` (the QR bezel), `silver` (the plate).

`graphite` is the only ramp that follows the theme, because it is *chrome*
rather than identity — a dark housing on a dark ground disappears. The others
represent something fixed (a brand, an emergency, a physical number plate) and
look the same at midnight as at noon.

**Motion is four durations and four curves, all in `AppMotion`.** Before Aug
2026 there were twenty-two hand-picked millisecond values across the widgets;
two things animating side by side at 300ms and 320ms do not read as
deliberate, they read as sloppy. List entrances use `AppMotion.staggerFor(i)`,
which caps the total run so the last card never arrives after the reader.

**Never metallic**, and these are hard limits:

- **QR modules.** Pure black on pure white. A gradient across a finder pattern
  destroys the contrast a scanner's binarisation depends on.
- **The printed sticker.** A five-stop ramp bands and muddies on a consumer
  printer, so the sheet keeps the flat `AppColors.heroGradient`.
- **Body copy backgrounds.** Text sits on solid ground, never on a moving
  highlight.

### Ramps are contrast-clamped

Every stop of every ramp is darkened until white body text on it clears WCAG AA
(4.5:1), and `test/contrast_test.dart` fails the build if that ever drifts.

This is not optional polish. A gradient is only as accessible as its worst stop,
and the literal design tokens did **not** hold: white on `#5B95F7` is 2.96:1 and
on the raw success green `#10B981` it is 2.54:1 — while the home hero runs muted
white copy across both. The palettes therefore carry darkened variants of the
brand colours rather than the tokens themselves. When adding a stop, run the
test rather than trusting your eye; several hand-picked values that looked
obviously fine measured at 3.8–4.1:1.

## Shape and spacing

- Radius: **12** inputs and buttons, **14** cards, **20** hero surfaces and the
  QR container. Tightened one step alongside the metal work — a machined edge
  is precise, and the corner radius is most of what says so.
- Card elevation is **0**. Depth comes from a soft shadow
  (`black.withOpacity(0.1)`, blur 20, offset `(0, 10)`) on hero surfaces only.
- Padding: 24 cards, 24 section, 32 hero. 16 only where space is genuinely
  tight.
- Spacing steps: 8 / 12 / 16 / 24 / 32.
- Button padding: horizontal 24, vertical 16.

## Type

**Plus Jakarta Sans** for display, **Inter** for body and labels. Both ship
bundled as variable fonts, so `AppText` sets `fontVariations` as well as
`fontWeight` — setting only `fontWeight` renders at the default axis position
on some Android builds. (This section used to say `SF Pro Display`, which was
never shipped and silently fell back to Roboto.)

Display tracking is **optical, not constant**: `_opticalTracking` tightens from
-0.3 at 18sp to -1.0 at 34sp. Counters and side-bearings scale with the glyph,
so one value across the whole scale leaves large headings looking gappy.

- App bar title: 18 / w600
- Section heading: 16 / w600
- Body: 14 / regular
- Caption and badge: 10–12
- License plate: 16 / w600 with `letterSpacing: 1.2` — plates always render
  monospaced-feeling and uppercase.

Panic-mode text starts at 24 and goes up. There is no upper bound.

## Component recipes

**Card** — white, radius 14, elevation 0, **padding 24**. The same 1.5rem the
web's `.card-body` uses: the app and the scan page are one product seen from
two ends, and side by side the app read cramped. Eight pixels of breathing room
on every card is most of what "considered" looks like at a glance. Icon in a tinted circle on
the left, title/subtitle stacked, chevron or action on the right.

**Primary button** — filled **graphite** (`#1A1E24`, the brand ramp's core),
white text, radius 12, elevation 0, 16/w600. One per screen.

Not bronze. Bronze is the *accent* — links, selected states, the icon on a
tinted badge, the QR reticle. It is what `primary` means when it is **ink**. As
a full-width fill it produces a slab of brown, and it disagreed with
`MetalButton`, which has always used the graphite ramp: the app had two
different primary buttons. `ElevatedButton`, `MetalButton` and the web's
`.btn-primary` are now the same colour.

The one exception is a primary button **on the hero**, where graphite on
graphite is nearly invisible. There it inverts to amber on near-black — the
only place amber runs at full strength.

**Input** — filled white, radius 12, 2px `#E5E7EB` border, `#2563EB` when
focused, `#DC2626` on error, content padding 16.

**Unread badge** — `#DC2626` pill, white 10/bold text, `99+` cap, offset
`right: -8, top: -6` on the nav icon.

**Empty state** — muted icon, a heading that says what is missing, a sentence
explaining why it matters, and the action that fixes it. Never a bare blank box.

**QR hero** — white container, radius 24, padding 32, soft shadow, QR centred,
plate below in letter-spaced w600, vehicle descriptor below that in muted text.

## The printable sticker

The sticker is **drawn on a canvas**, not composited from artwork:
`lib/utils/sticker_renderer.dart` holds `StickerPainter`, and the on-screen
preview (`CustomPaint`) and the exported PNG (`renderStickerPng`) both run it.
There is therefore no way for the preview to disagree with the print file —
change the painter and both move together.

A design is a **layout** crossed with a **theme**, and the two are separate so
adding a look is a row of colours rather than a new branch in the painter:

- `StickerLayout.banner` — colour band across the top, rest on bare paper.
- `StickerLayout.panel` — full-bleed colour with a floating white card.
- `StickerLayout.plain` — ink and rules only, no filled areas.

`StickerTheme` supplies the sheet, ink, muted ink, accent, band ramp and card
colour for one of those layouts, and `StickerStyle` is the stable identity that
pairs a label and description with a theme. Eight ship: `signature`, `bold`,
`minimal`, `midnight`, `ember`, `emerald`, `indigo`, `ivory`.

When adding a theme:

- Any band carrying white text must be dark enough to hold it. Two of the
  candidates that looked obviously fine measured under 4.5:1.
- Keep band ramps to two or three flat stops. A five-stop metallic ramp bands
  and muddies on a consumer printer.
- `StickerTheme.floodsInk` is true for anything that floods the sheet, and the
  picker surfaces it — nobody should discover the ink cost at the counter.

All geometry is expressed as a fraction of the sticker width, so a design
scales from a 100px chip thumbnail to a 1748px print master with no relayout.

The sheet is ISO A-ratio (`kStickerAspectRatio`), so it prints to A5 or A6 with
no cropping and no wasted margin.

The legacy artwork `assets/images/qr_template.svg` is **no longer used**. It is
left in the repo rather than deleted, but nothing references it.

Sticker-specific rules, all of which trump aesthetics:

- Maximum quiet zone around the QR — `_drawQrBlock` reserves 9% of the code
  block on every side and nothing is ever drawn inside it. A cramped code fails
  on a dirty windscreen.
- High contrast only — pure black on pure white. No gradients, no brand colour,
  no logo overlaying the code. Styles may colour the *sheet*; never the code.
- The instruction text must read at arm's length through glass: large, short,
  and in both English and Kannada, since this ships in Bangalore. The Kannada
  line uses a bundled subset of Noto Sans Kannada so a printed sheet renders
  identically on every device.
- Always scan-verify a changed sticker before shipping. Do not do this by eye
  alone:

  ```bash
  STICKER_OUT=/tmp/stickers flutter test test/sticker_renderer_test.dart
  python3 tool/verify_sticker_scan.py /tmp/stickers
  ```

  That decodes every style under downscaling, blur, tilt, glare and noise. The
  style list is discovered from the rendered PNGs, so a theme added in Dart is
  verified without editing the script. A Google Lens check on a real print is
  still worth doing on top of it.

### Getting it onto paper

`lib/utils/sticker_sheet.dart` is the layer between the sticker tile and a
printer. `SheetPlan.compute` takes whatever page dimensions it is handed and
picks the grid that prints the **largest** sticker — every factorisation of the
copy count is tried, because on a portrait page two A-ratio tiles stack and
four tile 2x2, and guessing wastes a third of the sheet.

`printStickerSheet` builds the sheet inside the print dialog's `onLayout`
callback, so the page handed over always matches the paper that was asked for.
The studio's page preview is drawn from the same `SheetPlan`, so what is on
screen is what comes out — including the margin, which is the part people are
surprised by.

**Paper and copies-per-sheet belong in the app, not in the system dialog.**
`printing` 5.14.3 forwards Android's `onLayout` to Dart only once, at job
start. Change the paper or orientation inside the system dialog and the request
never reaches us — the spooler waits forever on "Preparing preview…". Verified
on an API 37 emulator. The job is therefore declared `dynamicLayout: false`,
and the studio owns those choices with its own preview. Do not "simplify" that
by deferring to the dialog. Upgrading is not the way out either: `printing`
5.15.0 needs `xml ^7`, which `flutter_local_notifications` — the package the
whole alert path runs on — cannot coexist with.

Crop marks sit *outside* the sticker bounds. Nothing is ever drawn across the
sheet, because a cut line through a quiet zone is a code that does not scan.

## Accessibility

- Minimum tap target 48x48.
- Body contrast at least 4.5:1.
- Test every screen at 320dp width and 2.0x text scale — `qr_code_screen.dart`
  and `profile_screen.dart` have both had overflow regressions.
- Never encode meaning in colour alone; pair the alert red with an icon and a
  label.
