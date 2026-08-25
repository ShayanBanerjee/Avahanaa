import 'dart:ui' as ui;

import 'package:avahanaa/widgets/qr_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';

/// Guards on the styled QR.
///
/// The code is the product. It is drawn with rounded modules, softened finder
/// frames and a centre logo, and exactly one of those knobs can silently
/// destroy it — see [QrStyle.eyeOuterRadius]. A sweep measured where each one
/// stops decoding under the full degradation set (downscale, blur, tilt, glare,
/// noise):
///
/// | knob            | safe        | first failure | collapse |
/// |-----------------|-------------|---------------|----------|
/// | eyeOuterRadius  | 0.00 - 0.12 | 0.16          | 0.24     |
/// | moduleRadius    | 0.00 - 0.50 | none measured | none     |
/// | logoFraction    | 0.00 - 0.24 | 0.28          | -        |
///
/// These tests do not re-derive that — decoding needs OpenCV, which lives in
/// `tool/verify_sticker_scan.py`. What they do is stop the shipped style
/// drifting past the envelope that was measured, which is the failure mode that
/// would otherwise reach a windscreen unnoticed.
///
/// To re-run the sweep itself:
///
///     python3 tool/qr_style_sweep.py --emit > /tmp/sweep_variants.txt
///     flutter test test/qr_style_sweep_test.dart
///     python3 tool/qr_style_sweep.py /tmp/qrprobe
void main() {
  group('the shipped style stays inside the measured envelope', () {
    const style = AvahanaaQr.style;

    test('finder frames are barely rounded', () {
      expect(
        style.eyeOuterRadius,
        lessThanOrEqualTo(QrStyle.kMaxSafeEyeOuterRadius),
        reason:
            'above 0.12 the code loses distant scans, and at 0.24 it stops '
            'decoding entirely. Re-run tool/qr_style_sweep.py before raising.',
      );
    });

    test('module rounding stays within what was measured', () {
      expect(
        style.moduleRadius,
        lessThanOrEqualTo(QrStyle.kMaxSafeModuleRadius),
      );
    });

    test('the centre logo stays inside the redundancy budget', () {
      expect(
        style.logoFraction,
        lessThanOrEqualTo(QrStyle.kMaxSafeLogoFraction),
      );
    });

    test('error correction is high enough to pay for the logo', () {
      // Q (25%) or better. L and M cannot carry a centre occlusion safely.
      expect(
        AvahanaaQr.errorCorrectionLevel,
        anyOf(QrErrorCorrectLevel.Q, QrErrorCorrectLevel.H),
      );
    });
  });

  group('the payload still fits a version the sticker can print', () {
    test('the real payload stays at version 4 or below', () {
      final matrix = qrMatrixFor('https://avahanaa.com/n/qr-abc123def456');
      expect(
        matrix.moduleCount,
        lessThanOrEqualTo(33),
        reason:
            'more modules means smaller ones at a fixed sticker size, which is '
            'what actually fails at arm\'s length through glass',
      );
    });

    test('the matrix is cached rather than rebuilt per paint', () {
      const data = 'https://avahanaa.com/n/cache-check';
      final first = qrMatrixFor(data);
      final second = qrMatrixFor(data);
      expect(identical(first, second), isTrue);
    });
  });

  group('painting', () {
    testWidgets('renders without throwing at a realistic size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: AvahanaaQrView(
                  data: 'https://avahanaa.com/n/qr-abc123def456',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a missing logo asset', (tester) async {
      // AvahanaaQr.logo is null in a plain widget test, which is the same state
      // the app is in for the first few frames of a cold start.
      expect(AvahanaaQr.logo, isNull);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: AvahanaaQrView(data: 'https://avahanaa.com/n/x'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    test('rasterises to a real PNG', () async {
      final bytes = await renderQrPng(
        'https://avahanaa.com/n/qr-abc123def456',
        width: 400,
      );
      expect(bytes, isNotNull);
      expect(bytes!.sublist(0, 4), <int>[0x89, 0x50, 0x4E, 0x47]);
    });
  });

  group('the quiet zone is never painted into', () {
    test('the painter draws only inside the square it is given', () async {
      // Paint into a recorder larger than the code and check the outer band is
      // untouched white. A stray pixel in the quiet zone is a scan failure.
      const side = 300.0;
      const pad = 40.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, side + pad * 2, side + pad * 2),
        Paint()..color = const Color(0xFFFF0000),
      );
      canvas.save();
      canvas.translate(pad, pad);
      AvahanaaQrPainter(
        data: 'https://avahanaa.com/n/qr-abc123def456',
      ).paint(canvas, const Size(side, side));
      canvas.restore();

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (side + pad * 2).toInt(),
        (side + pad * 2).toInt(),
      );
      final data = await image.toByteData();
      image.dispose();
      picture.dispose();

      // Sample the margin: still the red ground, never black or white ink.
      final bytes = data!.buffer.asUint8List();
      final width = (side + pad * 2).toInt();
      int pixel(int x, int y) {
        final i = (y * width + x) * 4;
        return (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
      }

      expect(pixel(5, 5), 0xFF0000);
      expect(pixel(width - 6, 5), 0xFF0000);
      expect(pixel(5, width - 6), 0xFF0000);
    });
  });
}
