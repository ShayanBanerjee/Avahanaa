import 'dart:math' as math;

import 'package:avahanaa/theme/app_theme.dart';
import 'package:avahanaa/widgets/metal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrast audit for the metallic surfaces.
///
/// A gradient is only as accessible as its worst stop. Text that clears 4.5:1
/// against a ramp's base colour can still fail where the ramp lifts, and the
/// hero surfaces put muted white copy across their full width — so every stop
/// has to hold, not just the middle one.
///
/// This exists because the literal design tokens did not hold: `#5B95F7` gives
/// 2.96:1 against white and the raw success green `#10B981` gives 2.54:1, both
/// well under AA. The ramps in `MetalPalette` are deliberately darkened
/// versions, and this test is what stops them drifting back.
double _relativeLuminance(Color c) {
  double channel(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG AA for body text.
const double kAaBody = 4.5;

/// WCAG AA for text at 24px+ — panic-mode headlines qualify.
const double kAaLarge = 3.0;

void main() {
  group('white text on metal ramps', () {
    // `graphite` follows the theme, so it is audited in both palettes rather
    // than whichever one happened to be active when the test ran.
    void auditRamps(String label) {
      final ramps = <String, MetalPalette>{
        'brand': MetalPalette.brand,
        'alert': MetalPalette.alert,
        'success': MetalPalette.success,
        'graphite': MetalPalette.graphite,
      };

      ramps.forEach((name, palette) {
        test('$label $name clears AA body contrast at every stop', () {
          for (final stop in palette.colors) {
            final ratio = contrastRatio(AppColors.onDark, stop);
            expect(
              ratio,
              greaterThanOrEqualTo(kAaBody),
              reason:
                  '$label $name stop ${stop.toARGB32().toRadixString(16)} gives '
                  '${ratio.toStringAsFixed(2)}:1 against white, under $kAaBody',
            );
          }
        });
      });
    }

    group('light', () {
      setUp(() => AppColors.usePalette(AvahanaaPalette.light));
      auditRamps('light');
    });

    group('dark', () {
      setUp(() => AppColors.usePalette(AvahanaaPalette.dark));
      tearDown(() => AppColors.usePalette(AvahanaaPalette.light));
      auditRamps('dark');
    });

    test('the card ramp stays near-flat', () {
      // `slate` sits under body copy. If it ever develops a real gradient,
      // text starts sitting on a moving highlight, which the design system
      // forbids outright.
      for (final palette in <MetalPalette>[
        MetalPalette.slate,
      ]) {
        final spread = contrastRatio(palette.lift, palette.depth);
        expect(
          spread,
          lessThan(1.25),
          reason: 'the card ramp has become a visible gradient',
        );
      }
    });
  });

  group('panic mode', () {
    test('the alert banner CTA stays legible', () {
      // White button, alert-deep label — the one action someone walking fast
      // toward their car has to find.
      final ratio = contrastRatio(AppColors.surface, AppColors.alertDeep);
      expect(ratio, greaterThanOrEqualTo(kAaBody));
    });

    test('panic headline is large enough for its contrast floor', () {
      expect(AppText.panicTitle.fontSize, greaterThanOrEqualTo(24));
    });
  });

  // Both palettes, not just the one that happens to be active.
  //
  // Dark mode is not an inversion — the accents had to be lifted, because
  // `#2563EB` gives 2.4:1 on a near-black ground and is simply unreadable. A
  // gate that only checked light would let the night palette rot silently,
  // and the person reading it is doing so at night by definition.
  group('core text tokens on their backgrounds', () {
    const palettes = <String, AvahanaaPalette>{
      'light': AvahanaaPalette.light,
      'dark': AvahanaaPalette.dark,
    };

    palettes.forEach((name, p) {
      group(name, () {
        test('body text on the scaffold background clears AA', () {
          expect(
            contrastRatio(p.textPrimary, p.background),
            greaterThanOrEqualTo(kAaBody),
          );
        });

        test('secondary text on surface clears AA', () {
          expect(
            contrastRatio(p.textSecondary, p.surface),
            greaterThanOrEqualTo(kAaBody),
          );
        });

        test('tertiary text clears AA — it is used for overlines and captions', () {
          // This one was failing outright at 2.54:1 before the slate move.
          // Small and quiet is not the same as unreadable.
          expect(
            contrastRatio(p.textTertiary, p.surface),
            greaterThanOrEqualTo(kAaBody),
          );
        });

        test('primary clears AA on surface for links and labels', () {
          expect(
            contrastRatio(p.primary, p.surface),
            greaterThanOrEqualTo(kAaBody),
          );
        });

        test('the alert colour clears AA on both grounds', () {
          // Red means "somebody is at your car". If it is the one thing on the
          // screen that cannot be read, the screen has failed.
          expect(
            contrastRatio(p.alert, p.surface),
            greaterThanOrEqualTo(kAaBody),
            reason: '\$name alert on surface',
          );
          expect(
            contrastRatio(p.alert, p.background),
            greaterThanOrEqualTo(kAaBody),
            reason: '\$name alert on background',
          );
        });

        test('the ink versions of success and warning clear AA', () {
          // `success` is a fill — white sits on it, not beside it — so the
          // token that has to clear AA against a pale ground is `successDark`,
          // which is what the reply confirmations are written in. It was at
          // 3.77:1 in light until this test was written.
          expect(
            contrastRatio(p.successDark, p.surface),
            greaterThanOrEqualTo(kAaBody),
            reason: '\$name successDark on surface',
          );
          expect(
            contrastRatio(p.successDark, p.successTint),
            greaterThanOrEqualTo(kAaBody),
            reason: '\$name successDark on its own tint',
          );

          // `warning` is drawn as an icon glyph on `warningTint` — the amber
          // badge on a parking alert. At 2.07:1 that was a decorative smudge.
          expect(
            contrastRatio(p.warning, p.warningTint),
            greaterThanOrEqualTo(kAaBody),
            reason: '\$name warning on its own tint',
          );
        });

        test('borders are visible against the surfaces they divide', () {
          // Not a text ratio — a hairline only has to be perceivable. But a
          // border that matches its background is a card with no edge.
          expect(
            contrastRatio(p.border, p.surface),
            greaterThan(1.12),
            reason: '\$name border vanishes on surface',
          );
        });
      });
    });

    test('the print palette never follows the theme', () {
      // The sticker ends up as ink on paper. Dark mode is a property of a
      // screen at night; a sheet of A4 does not have one.
      expect(AppPrint.heroGradient.first, const Color(0xFF1F4FB8));
      expect(AppPrint.brandDeep, const Color(0xFF122A66));
    });
  });
}
