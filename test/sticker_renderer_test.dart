import 'dart:io';

import 'package:avahanaa/utils/sticker_renderer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the printable sticker in every style.
///
/// Set `STICKER_OUT=/some/dir` to also write the PNGs to disk for a visual
/// check — the sticker is a physical artifact, and the only real review of one
/// is looking at it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Tests do not pick up pubspec fonts automatically; without this the
    // rendered PNG would be full of fallback boxes and prove nothing.
    await _loadFont('Inter', 'assets/fonts/Inter-Variable.ttf');
    await _loadFont(
      'PlusJakartaSans',
      'assets/fonts/PlusJakartaSans-Variable.ttf',
    );
    await _loadFont(
      'NotoSansKannada',
      'assets/fonts/NotoSansKannada-Sticker.ttf',
    );
  });

  const spec = StickerSpec(
    qrData: 'https://avahanaa.com/n/qr-abc123def456',
    plate: 'KA01AB1234',
    descriptor: 'White Maruti Swift',
  );

  final outDir = Platform.environment['STICKER_OUT'];

  for (final style in StickerStyle.values) {
    test('renders the ${style.name} sticker to a PNG', () async {
      final bytes = await renderStickerPng(
        spec.copyWith(style: style),
        width: 900,
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(4000));

      // PNG magic number — proves we produced a real image, not an empty buffer.
      expect(bytes.sublist(0, 4), <int>[0x89, 0x50, 0x4E, 0x47]);

      if (outDir != null) {
        final file = File('$outDir/sticker-${style.name}.png');
        await file.writeAsBytes(bytes, flush: true);
      }
    });
  }

  test('renders at print resolution without throwing', () async {
    final bytes = await renderStickerPng(
      spec,
      width: StickerSize.print.pixelWidth,
    );
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(10000));
  });

  test('renders when the vehicle has no plate or descriptor', () async {
    for (final style in StickerStyle.values) {
      final bytes = await renderStickerPng(
        const StickerSpec(
          qrData: 'https://avahanaa.com/n/qr-1',
        ).copyWith(style: style),
        width: 600,
      );
      expect(bytes, isNotNull, reason: 'style ${style.name} failed');
    }
  });

  test('every style exposes a label and description for the picker', () {
    for (final style in StickerStyle.values) {
      expect(style.label, isNotEmpty);
      expect(style.description, isNotEmpty);
    }
  });
}

Future<void> _loadFont(String family, String assetPath) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(assetPath));
  await loader.load();
}
