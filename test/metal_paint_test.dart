import 'package:avahanaa/theme/app_theme.dart';
import 'package:avahanaa/widgets/metal.dart';
import 'package:flutter/material.dart';
import 'package:avahanaa/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Metal surfaces have to actually paint.
///
/// `Metal.surface` once returned a `BoxDecoration` carrying both a
/// `borderRadius` and a `Border` with a white top and a black bottom. Flutter
/// forbids that combination — "a borderRadius can only be given on borders
/// with uniform colors" — and the assertion fires during *paint*, not layout.
/// The result was silent in every way that matters: no overflow, no failing
/// widget test, no analyzer complaint. The button simply painted as a bare
/// gradient bar with its label missing, in every build of the app.
///
/// These tests pump the real widget and force a paint, which is the only thing
/// that would have caught it.
void main() {
  Future<void> pumpAndPaint(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        theme: AvahanaaTheme.light(),
        home: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('MetalButton paints its label and icon', (tester) async {
    await pumpAndPaint(
      tester,
      MetalButton(
        label: 'Print this sheet',
        icon: Icons.print_rounded,
        onPressed: () {},
      ),
    );

    expect(
      tester.takeException(),
      isNull,
      reason: 'the metal surface failed to paint',
    );
    expect(find.text('Print this sheet'), findsOneWidget);
    expect(find.byIcon(Icons.print_rounded), findsOneWidget);
  });

  testWidgets('MetalButton paints in its busy state', (tester) async {
    await pumpAndPaint(
      tester,
      const MetalButton(label: 'Preparing…', busy: true),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a disabled MetalButton still paints', (tester) async {
    await pumpAndPaint(tester, const MetalButton(label: 'Unavailable'));
    expect(tester.takeException(), isNull);
    expect(find.text('Unavailable'), findsOneWidget);
  });

  test('Metal.surface never pairs a radius with a non-uniform border', () {
    for (final palette in <MetalPalette>[
      MetalPalette.brand,
      MetalPalette.alert,
      MetalPalette.success,
      MetalPalette.graphite,
      MetalPalette.silver,
    ]) {
      final decoration = Metal.surface(
        palette,
        radius: AppRadius.controlAll,
        shadows: Metal.lift(palette.core),
      );

      final border = decoration.border;
      expect(
        border == null || border.isUniform,
        isTrue,
        reason:
            'a rounded BoxDecoration with a non-uniform border aborts paint, '
            'which blanks the control instead of failing loudly',
      );
    }
  });
}
