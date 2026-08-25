import 'dart:io';
import 'dart:ui' as ui;

import 'package:avahanaa/widgets/qr_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders bare QR codes across a parameter sweep so the decoder can say where
/// each styling knob stops working.
///
/// This is a measuring instrument, not a guard — it is skipped unless a sweep
/// spec is present, so `flutter test` stays fast. `test/qr_style_test.dart`
/// holds the assertions derived from what this measured.
///
///     python3 tool/qr_style_sweep.py --emit > /tmp/sweep_variants.txt
///     flutter test test/qr_style_sweep_test.dart
///     python3 tool/qr_style_sweep.py /tmp/qrprobe
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const payload = 'https://avahanaa.com/n/qr-abc123def456';
  final out = Directory('/tmp/qrprobe')..createSync(recursive: true);

  setUpAll(() async {
    await AvahanaaQr.loadLogo();
  });

  final specFile = File('/tmp/sweep_variants.txt');

  testWidgets('render sweep', (tester) async {
    final spec = specFile.readAsLinesSync();
    await tester.runAsync(() async {
      for (final line in spec) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        final style = QrStyle(
          moduleRadius: double.parse(parts[1]),
          eyeOuterRadius: double.parse(parts[2]),
          eyeInnerRadius: double.parse(parts[3]),
          logoFraction: double.parse(parts[4]),
        );
        final bytes = await _render(payload, style);
        File('${out.path}/${parts[0]}.png').writeAsBytesSync(bytes);
      }
    });
  }, skip: !specFile.existsSync());
}

Future<List<int>> _render(String data, QrStyle style) async {
  const size = 600.0;
  const quietZone = size * 0.09;
  const inner = size - quietZone * 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.save();
  canvas.translate(quietZone, quietZone);
  AvahanaaQrPainter(data: data, style: style).paint(
    canvas,
    const Size(inner, inner),
  );
  canvas.restore();

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return png!.buffer.asUint8List();
}
