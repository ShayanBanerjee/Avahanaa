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
    const ramps = <String, MetalPalette>{
      'brand': MetalPalette.brand,
      'alert': MetalPalette.alert,
      'success': MetalPalette.success,
      'graphite': MetalPalette.graphite,
    };

    ramps.forEach((name, palette) {
      test('$name clears AA body contrast at every stop', () {
        for (final stop in palette.colors) {
          final ratio = contrastRatio(AppColors.onDark, stop);
          expect(
            ratio,
            greaterThanOrEqualTo(kAaBody),
            reason:
                '$name stop ${stop.toARGB32().toRadixString(16)} gives '
                '${ratio.toStringAsFixed(2)}:1 against white, under $kAaBody',
          );
        }
      });
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

  group('core text tokens on their backgrounds', () {
    test('body text on the scaffold background clears AA', () {
      expect(
        contrastRatio(AppColors.textPrimary, AppColors.background),
        greaterThanOrEqualTo(kAaBody),
      );
    });

    test('secondary text on surface clears AA', () {
      expect(
        contrastRatio(AppColors.textSecondary, AppColors.surface),
        greaterThanOrEqualTo(kAaBody),
      );
    });

    test('primary on white clears AA for links and labels', () {
      expect(
        contrastRatio(AppColors.primary, AppColors.surface),
        greaterThanOrEqualTo(kAaBody),
      );
    });
  });
}
