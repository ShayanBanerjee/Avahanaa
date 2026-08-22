/// Draws the printable Avahanaa sticker.
///
/// Everything here paints onto a bare [Canvas] rather than being composed from
/// widgets, for one reason: the on-screen preview and the exported PNG run the
/// *same* code. A `CustomPaint` uses [StickerPainter] directly, and
/// [renderStickerPng] replays it into a [ui.PictureRecorder]. What the owner
/// approves on screen is exactly what comes out of the printer.
///
/// All geometry is expressed as a fraction of the sticker width, so a design
/// scales from a 120px thumbnail to a 2000px print master with no relayout.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/qr_visual.dart';

/// Sticker designs the owner can choose between.
enum StickerStyle {
  /// Brand header band on white. The default.
  signature,

  /// Full-bleed brand gradient with a floating white code card.
  bold,

  /// Black on white, nothing else. Cheapest to print and the most forgiving
  /// to scan, which makes it the right answer for a windscreen that lives
  /// outdoors.
  minimal;

  String get label => switch (this) {
    StickerStyle.signature => 'Signature',
    StickerStyle.bold => 'Bold',
    StickerStyle.minimal => 'Minimal',
  };

  String get description => switch (this) {
    StickerStyle.signature => 'Branded header on white paper',
    StickerStyle.bold => 'High-visibility colour panel',
    StickerStyle.minimal => 'Black and white — best for scanning',
  };
}

/// Everything the sticker needs to draw itself.
@immutable
class StickerSpec {
  const StickerSpec({
    required this.qrData,
    this.plate = '',
    this.descriptor = '',
    this.style = StickerStyle.signature,
  });

  final String qrData;
  final String plate;
  final String descriptor;
  final StickerStyle style;

  StickerSpec copyWith({StickerStyle? style}) => StickerSpec(
    qrData: qrData,
    plate: plate,
    descriptor: descriptor,
    style: style ?? this.style,
  );
}

/// Sticker proportions.
///
/// ISO A-series ratio, so the exported image prints onto A5 or A6 with no
/// cropping and no wasted margin — the previous artwork was 1:1.63 and always
/// left a band of dead paper.
const double kStickerAspectRatio = 1 / 1.4142;

// ---------------------------------------------------------------------------
// Copy
// ---------------------------------------------------------------------------

abstract final class _Copy {
  static const String wordmark = 'AVAHANAA';
  static const String headline = 'SCAN TO ALERT\nTHE OWNER';

  /// "Scan to inform the owner." Reviewed-by-a-native-speaker pending — see
  /// the note in the QR screen docs.
  static const String headlineKannada = 'ಮಾಲೀಕರಿಗೆ ತಿಳಿಸಲು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ';

  static const String subline = 'No app needed — just point your camera';
  static const String domain = 'avahanaa.com';
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class StickerPainter extends CustomPainter {
  const StickerPainter({required this.spec, this.qrImage});

  final StickerSpec spec;

  /// Pre-rasterised QR. Supplying one keeps the preview cheap on repaint; when
  /// null the code is painted directly, which is what the PNG export does.
  final ui.Image? qrImage;

  @override
  void paint(Canvas canvas, Size size) {
    switch (spec.style) {
      case StickerStyle.signature:
        _paintSignature(canvas, size);
      case StickerStyle.bold:
        _paintBold(canvas, size);
      case StickerStyle.minimal:
        _paintMinimal(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant StickerPainter old) {
    return old.spec.style != spec.style ||
        old.spec.qrData != spec.qrData ||
        old.spec.plate != spec.plate ||
        old.spec.descriptor != spec.descriptor ||
        old.qrImage != qrImage;
  }

  // -- Styles -------------------------------------------------------------

  void _paintSignature(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.06;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white,
    );

    // Brand band across the top.
    final bandHeight = h * 0.115;
    final bandRect = Rect.fromLTWH(0, 0, w, bandHeight);
    canvas.drawRect(
      bandRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: AppColors.heroGradient,
        ).createShader(bandRect),
    );

    _drawText(
      canvas,
      _Copy.wordmark,
      center: Offset(w / 2, bandHeight / 2),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.088,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: Colors.white,
        letterSpacing: w * 0.014,
        height: 1.0,
      ),
      maxWidth: w - margin * 2,
    );

    var y = bandHeight + h * 0.045;

    y = _drawText(
      canvas,
      _Copy.headline,
      topCenter: Offset(w / 2, y),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.086,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: const Color(0xFF111827),
        height: 1.12,
        letterSpacing: w * 0.002,
      ),
      maxWidth: w - margin * 2,
    );

    y += h * 0.024;
    y = _drawText(
      canvas,
      _Copy.headlineKannada,
      topCenter: Offset(w / 2, y),
      style: TextStyle(
        fontFamily: AppFonts.kannada,
        fontSize: w * 0.055,
        color: AppColors.primaryDeep,
        height: 1.35,
      ),
      maxWidth: w - margin * 2,
    );

    // Footer is laid out from the bottom up, so the QR gets the slack.
    var bottom = h - margin * 0.9;
    bottom = _drawTextUp(
      canvas,
      _Copy.domain,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.045,
        fontWeight: FontWeight.w700,
        fontVariations: const [ui.FontVariation('wght', 700)],
        color: AppColors.primary,
        letterSpacing: w * 0.002,
      ),
      maxWidth: w - margin * 2,
    );

    bottom -= h * 0.022;
    if (spec.plate.trim().isNotEmpty) {
      final plateHeight = w * 0.115;
      _drawPlate(
        canvas,
        center: Offset(w / 2, bottom - plateHeight / 2),
        height: plateHeight,
        maxWidth: w - margin * 2,
      );
      bottom -= plateHeight + h * 0.016;
    }

    bottom -= h * 0.004;
    bottom = _drawTextUp(
      canvas,
      _Copy.subline,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.042,
        color: const Color(0xFF4B5563),
        height: 1.3,
      ),
      maxWidth: w - margin * 2,
    );

    _drawQrBlock(
      canvas,
      available: Rect.fromLTRB(margin, y + h * 0.02, w - margin, bottom - h * 0.02),
      framed: true,
    );
  }

  void _paintBold(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.055;

    final backdrop = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      backdrop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ).createShader(backdrop),
    );

    _drawText(
      canvas,
      _Copy.wordmark,
      topCenter: Offset(w / 2, h * 0.045),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.075,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: Colors.white,
        letterSpacing: w * 0.016,
        height: 1.0,
      ),
      maxWidth: w - margin * 2,
    );

    // White card holds the headline and the code, so the code always sits on
    // pure white no matter how saturated the background is.
    final cardTop = h * 0.135;
    final cardBottom = h - h * 0.115;
    final cardRect = Rect.fromLTRB(margin, cardTop, w - margin, cardBottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, Radius.circular(w * 0.055)),
      Paint()..color = Colors.white,
    );

    final inner = w * 0.055;
    var y = cardTop + inner * 1.1;

    y = _drawText(
      canvas,
      _Copy.headline,
      topCenter: Offset(w / 2, y),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.082,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: const Color(0xFF111827),
        height: 1.12,
      ),
      maxWidth: cardRect.width - inner * 2,
    );

    y += h * 0.022;
    y = _drawText(
      canvas,
      _Copy.headlineKannada,
      topCenter: Offset(w / 2, y),
      style: TextStyle(
        fontFamily: AppFonts.kannada,
        fontSize: w * 0.05,
        color: AppColors.primaryDeep,
        height: 1.35,
      ),
      maxWidth: cardRect.width - inner * 2,
    );

    var bottom = cardBottom - inner * 0.9;
    if (spec.plate.trim().isNotEmpty) {
      final plateHeight = w * 0.108;
      _drawPlate(
        canvas,
        center: Offset(w / 2, bottom - plateHeight / 2),
        height: plateHeight,
        maxWidth: cardRect.width - inner * 2,
      );
      bottom -= plateHeight + h * 0.014;
    }

    bottom = _drawTextUp(
      canvas,
      _Copy.subline,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.04,
        color: const Color(0xFF4B5563),
        height: 1.3,
      ),
      maxWidth: cardRect.width - inner * 2,
    );

    _drawQrBlock(
      canvas,
      available: Rect.fromLTRB(
        cardRect.left + inner,
        y + h * 0.015,
        cardRect.right - inner,
        bottom - h * 0.015,
      ),
      framed: false,
    );

    _drawText(
      canvas,
      _Copy.domain,
      center: Offset(w / 2, (cardBottom + h) / 2),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.042,
        fontWeight: FontWeight.w700,
        fontVariations: const [ui.FontVariation('wght', 700)],
        color: Colors.white,
        letterSpacing: w * 0.004,
      ),
      maxWidth: w - margin * 2,
    );
  }

  void _paintMinimal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.07;
    const ink = Color(0xFF000000);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white,
    );

    var y = h * 0.055;
    y = _drawText(
      canvas,
      _Copy.headline,
      topCenter: Offset(w / 2, y),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.078,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: ink,
        height: 1.12,
      ),
      maxWidth: w - margin * 2,
    );

    y += h * 0.024;
    y = _drawText(
      canvas,
      _Copy.headlineKannada,
      topCenter: Offset(w / 2, y),
      style: TextStyle(
        fontFamily: AppFonts.kannada,
        fontSize: w * 0.052,
        color: ink,
        height: 1.35,
      ),
      maxWidth: w - margin * 2,
    );

    y += h * 0.018;
    canvas.drawLine(
      Offset(margin, y),
      Offset(w - margin, y),
      Paint()
        ..color = ink
        ..strokeWidth = w * 0.005,
    );

    var bottom = h - margin * 0.8;
    bottom = _drawTextUp(
      canvas,
      '${_Copy.wordmark}  ·  ${_Copy.domain}',
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.042,
        fontWeight: FontWeight.w700,
        fontVariations: const [ui.FontVariation('wght', 700)],
        color: ink,
        letterSpacing: w * 0.004,
      ),
      maxWidth: w - margin * 2,
    );

    bottom -= h * 0.014;
    if (spec.plate.trim().isNotEmpty) {
      bottom = _drawTextUp(
        canvas,
        spec.plate.trim().toUpperCase(),
        bottomCenter: Offset(w / 2, bottom),
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: w * 0.058,
          fontWeight: FontWeight.w700,
          fontVariations: const [ui.FontVariation('wght', 700)],
          color: ink,
          letterSpacing: w * 0.015,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
        maxWidth: w - margin * 2,
      );
      bottom -= h * 0.01;
    }

    bottom = _drawTextUp(
      canvas,
      _Copy.subline,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.042,
        color: ink,
        height: 1.3,
      ),
      maxWidth: w - margin * 2,
    );

    bottom -= h * 0.008;
    canvas.drawLine(
      Offset(margin, bottom),
      Offset(w - margin, bottom),
      Paint()
        ..color = ink
        ..strokeWidth = w * 0.005,
    );

    _drawQrBlock(
      canvas,
      available: Rect.fromLTRB(
        margin,
        y + h * 0.02,
        w - margin,
        bottom - h * 0.02,
      ),
      framed: false,
    );
  }

  // -- Primitives ---------------------------------------------------------

  /// Paints the code centred in [available], on white, with a quiet zone.
  ///
  /// The quiet zone is not decoration. A QR needs clear white around it or the
  /// scanner cannot find its bounds, and on a windscreen — behind glass, at an
  /// angle, in glare — it is the first thing that fails. It is sized generously
  /// here and nothing is ever drawn inside it.
  void _drawQrBlock(Canvas canvas, {required Rect available, required bool framed}) {
    if (available.width <= 0 || available.height <= 0) return;

    final side = math.min(available.width, available.height);
    if (side <= 0) return;

    final box = Rect.fromCenter(
      center: available.center,
      width: side,
      height: side,
    );

    if (framed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(side * 0.06)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(side * 0.06)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.008
          ..color = const Color(0xFFE5E7EB),
      );
    } else {
      canvas.drawRect(box, Paint()..color = Colors.white);
    }

    final quietZone = side * 0.09;
    final codeSide = side - quietZone * 2;
    if (codeSide <= 0) return;

    canvas.save();
    canvas.translate(box.left + quietZone, box.top + quietZone);
    final image = qrImage;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, codeSide, codeSide),
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      AvahanaaQr.painter(spec.qrData).paint(canvas, Size(codeSide, codeSide));
    }
    canvas.restore();
  }

  /// A miniature of the physical Indian plate.
  void _drawPlate(
    Canvas canvas, {
    required Offset center,
    required double height,
    required double maxWidth,
  }) {
    final value = spec.plate.trim().toUpperCase();
    if (value.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: height * 0.46,
          fontWeight: FontWeight.w700,
          fontVariations: const [ui.FontVariation('wght', 700)],
          color: const Color(0xFF111827),
          letterSpacing: height * 0.05,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final bandWidth = height * 0.42;
    final padding = height * 0.22;
    final width = math.min(
      bandWidth + padding * 2 + textPainter.width,
      maxWidth,
    );

    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    final radius = Radius.circular(height * 0.16);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = height * 0.05
        ..color = const Color(0xFF111827),
    );

    // Blue IND band on the left.
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, radius));
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, bandWidth, rect.height),
      Paint()..color = const Color(0xFF1E3A8A),
    );
    _drawText(
      canvas,
      'IND',
      center: Offset(rect.left + bandWidth / 2, rect.center.dy + height * 0.24),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: height * 0.19,
        fontWeight: FontWeight.w700,
        fontVariations: const [ui.FontVariation('wght', 700)],
        color: Colors.white,
        height: 1.0,
      ),
      maxWidth: bandWidth,
    );
    canvas.restore();

    textPainter.paint(
      canvas,
      Offset(
        rect.left + bandWidth + padding,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  /// Draws [text] and returns the y coordinate just below it.
  double _drawText(
    Canvas canvas,
    String text, {
    required TextStyle style,
    required double maxWidth,
    Offset? center,
    Offset? topCenter,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);

    final origin = center != null
        ? Offset(center.dx - painter.width / 2, center.dy - painter.height / 2)
        : Offset(topCenter!.dx - painter.width / 2, topCenter.dy);

    painter.paint(canvas, origin);
    return origin.dy + painter.height;
  }

  /// Draws [text] sitting on [bottomCenter], returning its top edge — so a
  /// footer can be stacked upwards without knowing its own height in advance.
  double _drawTextUp(
    Canvas canvas,
    String text, {
    required Offset bottomCenter,
    required TextStyle style,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);

    final top = bottomCenter.dy - painter.height;
    painter.paint(canvas, Offset(bottomCenter.dx - painter.width / 2, top));
    return top;
  }
}

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

/// Print resolutions offered to the owner.
enum StickerSize {
  /// Fits a phone screenshot / messaging app.
  share(1000, 'Share', 'Good for WhatsApp and email'),

  /// Enough pixels for a crisp A5 at ~300dpi.
  print(1748, 'Print', 'A5 at 300dpi — take this to a print shop');

  const StickerSize(this.pixelWidth, this.label, this.description);

  final int pixelWidth;
  final String label;
  final String description;
}

/// Rasterises [spec] to PNG bytes at [width] logical pixels.
Future<Uint8List?> renderStickerPng(
  StickerSpec spec, {
  int width = 1000,
}) async {
  final height = (width / kStickerAspectRatio).round();
  final size = Size(width.toDouble(), height.toDouble());

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);

  // Paper is white even where a style does not paint to the edge, so a
  // transparent PNG never reaches a printer.
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
  StickerPainter(spec: spec).paint(canvas, size);

  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  } finally {
    picture.dispose();
  }
}
