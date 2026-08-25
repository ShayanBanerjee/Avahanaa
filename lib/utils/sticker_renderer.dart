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
///
/// ## Themes
///
/// A sticker is a [StickerLayout] (where the ink goes) plus a [StickerTheme]
/// (what colour it is). Those are separate on purpose: three layouts times a
/// palette table gives every theme below without a new branch in the painter,
/// so adding a look is a row of colours rather than a new `case`.
///
/// One thing never varies, whatever the theme: the code is pure black on pure
/// white inside a generous quiet zone. Themes colour the *sheet*, never the
/// symbol — see [_drawQrBlock].
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/qr_visual.dart';

// ---------------------------------------------------------------------------
// Themes
// ---------------------------------------------------------------------------

/// Where the ink goes. Colour is [StickerTheme]'s job, not this one's.
enum StickerLayout {
  /// A colour band across the top, everything else on the bare sheet.
  banner,

  /// Full-bleed colour with a floating card holding the message and the code.
  panel,

  /// Ink on paper, ruled top and bottom. No filled areas at all, so it costs
  /// almost nothing to print and survives a cheap printer.
  plain,
}

/// The palette and layout behind one sticker design.
///
/// Every colour here lands on paper, so the values are chosen for a consumer
/// printer rather than for a screen: flat two- and three-stop ramps (a
/// five-stop metallic ramp bands and muddies), and any band carrying white
/// text is dark enough to hold it.
@immutable
class StickerTheme {
  const StickerTheme({
    required this.layout,
    required this.band,
    this.sheet = const Color(0xFFFFFFFF),
    this.ink = const Color(0xFF111827),
    this.mutedInk = const Color(0xFF4B5563),
    this.accent = AppColors.primaryDeep,
    this.onBand = const Color(0xFFFFFFFF),
    this.card = const Color(0xFFFFFFFF),
    this.rule = const Color(0xFF111827),
  });

  /// A design with no filled areas — cheapest to print, most forgiving to scan.
  const StickerTheme.plain({
    Color ink = const Color(0xFF000000),
    this.sheet = const Color(0xFFFFFFFF),
    Color? accent,
    Color? mutedInk,
  }) : layout = StickerLayout.plain,
       band = const <Color>[Color(0xFF000000)],
       ink = ink,
       mutedInk = mutedInk ?? ink,
       accent = accent ?? ink,
       onBand = const Color(0xFFFFFFFF),
       card = const Color(0xFFFFFFFF),
       rule = ink;

  final StickerLayout layout;

  /// The sheet's colour field: the header band for [StickerLayout.banner], the
  /// full-bleed backdrop for [StickerLayout.panel]. Two or three stops.
  final List<Color> band;

  /// Paper colour. Almost always white — a printer cannot print white, so a
  /// tinted sheet means a full-bleed flood of ink.
  final Color sheet;

  /// Headline colour on the sheet (or on [card] for a panel design).
  final Color ink;

  /// Supporting copy.
  final Color mutedInk;

  /// The Kannada line and the domain footer.
  final Color accent;

  /// Text sitting directly on [band].
  final Color onBand;

  /// The floating card in a panel design.
  final Color card;

  /// Rules in a plain design.
  final Color rule;

  /// True when the design floods the sheet with colour. Surfaced in the
  /// picker so nobody discovers it at the print shop.
  bool get floodsInk =>
      layout == StickerLayout.panel || sheet != const Color(0xFFFFFFFF);
}

/// Sticker designs the owner can choose between.
///
/// The enum is the stable identity (it names the exported file and could be
/// persisted later); everything visual lives in [theme], so a design changes
/// without the value moving.
enum StickerStyle {
  /// Brand header band on white. The default.
  signature(
    'Signature',
    'Branded header on white paper',
    StickerTheme(layout: StickerLayout.banner, band: AppColors.heroGradient),
  ),

  /// Full-bleed brand gradient with a floating white code card.
  bold(
    'Bold',
    'High-visibility colour panel — uses a lot of ink',
    StickerTheme(layout: StickerLayout.panel, band: AppColors.heroGradient),
  ),

  /// Black on white, nothing else. Cheapest to print and the most forgiving
  /// to scan, which makes it the right answer for a windscreen that lives
  /// outdoors.
  minimal(
    'Minimal',
    'Black and white — best for scanning',
    StickerTheme.plain(),
  ),

  /// Graphite panel. Reads as hardware rather than as a leaflet.
  midnight(
    'Midnight',
    'Deep graphite panel with a white code card',
    StickerTheme(
      layout: StickerLayout.panel,
      band: <Color>[Color(0xFF39424F), Color(0xFF212836), Color(0xFF12171F)],
      accent: Color(0xFF1F2937),
    ),
  ),

  /// Rust and amber. The one that still catches an eye at dusk, when a blue
  /// sheet behind glass goes flat.
  ember(
    'Ember',
    'Warm rust header — easiest to spot at dusk',
    StickerTheme(
      layout: StickerLayout.banner,
      band: <Color>[Color(0xFFC2410C), Color(0xFF9A3412), Color(0xFF7C2D12)],
      accent: Color(0xFF9A3412),
    ),
  ),

  /// Deep anodised green — the "everything is fine" end of the palette.
  emerald(
    'Emerald',
    'Calm green header on white paper',
    StickerTheme(
      layout: StickerLayout.banner,
      band: <Color>[Color(0xFF0B845C), Color(0xFF077353), Color(0xFF045C43)],
      accent: Color(0xFF045C43),
    ),
  ),

  /// Indigo panel. Formal, and the closest thing here to an office document.
  indigo(
    'Indigo',
    'Indigo panel — uses a lot of ink',
    StickerTheme(
      layout: StickerLayout.panel,
      band: <Color>[Color(0xFF4338CA), Color(0xFF3730A3), Color(0xFF312E81)],
      accent: Color(0xFF312E81),
    ),
  ),

  /// Warm paper, espresso ink. Plain-layout economics with a softer face than
  /// [minimal] — the code still sits on its own white tile.
  ivory(
    'Ivory',
    'Warm cream paper with espresso ink',
    StickerTheme.plain(
      sheet: Color(0xFFF7F1E6),
      ink: Color(0xFF3B2F2A),
      mutedInk: Color(0xFF5C4B42),
      accent: Color(0xFF7C4A22),
    ),
  );

  const StickerStyle(this.label, this.description, this.theme);

  final String label;
  final String description;
  final StickerTheme theme;
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

  /// "White Maruti Swift" — what the person standing at the car sees. Printed
  /// under the plate so a scanner can confirm they are at the right vehicle
  /// before they send an alert.
  final String descriptor;

  final StickerStyle style;

  StickerTheme get theme => style.theme;

  StickerSpec copyWith({
    StickerStyle? style,
    String? qrData,
    String? plate,
    String? descriptor,
  }) => StickerSpec(
    qrData: qrData ?? this.qrData,
    plate: plate ?? this.plate,
    descriptor: descriptor ?? this.descriptor,
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
    final theme = spec.theme;
    switch (theme.layout) {
      case StickerLayout.banner:
        _paintBanner(canvas, size, theme);
      case StickerLayout.panel:
        _paintPanel(canvas, size, theme);
      case StickerLayout.plain:
        _paintPlain(canvas, size, theme);
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

  // -- Layouts ------------------------------------------------------------

  void _paintBanner(Canvas canvas, Size size, StickerTheme theme) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.06;

    _fillSheet(canvas, size, theme);

    // Brand band across the top.
    final bandHeight = h * 0.115;
    final bandRect = Rect.fromLTWH(0, 0, w, bandHeight);
    canvas.drawRect(bandRect, Paint()..shader = _bandShader(theme, bandRect));

    _drawText(
      canvas,
      _Copy.wordmark,
      center: Offset(w / 2, bandHeight / 2),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.088,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: theme.onBand,
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
        color: theme.ink,
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
        color: theme.accent,
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
        color: theme.accent,
        letterSpacing: w * 0.002,
      ),
      maxWidth: w - margin * 2,
    );

    bottom -= h * 0.016;
    bottom = _drawVehicleBlock(
      canvas,
      bottom: bottom,
      width: w,
      height: h,
      maxWidth: w - margin * 2,
      plateHeight: w * 0.115,
      theme: theme,
    );

    bottom -= h * 0.004;
    bottom = _drawTextUp(
      canvas,
      _Copy.subline,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.042,
        color: theme.mutedInk,
        height: 1.3,
      ),
      maxWidth: w - margin * 2,
    );

    _drawQrBlock(
      canvas,
      available: Rect.fromLTRB(
        margin,
        y + h * 0.02,
        w - margin,
        bottom - h * 0.02,
      ),
      framed: true,
    );
  }

  void _paintPanel(Canvas canvas, Size size, StickerTheme theme) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.055;

    final backdrop = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(backdrop, Paint()..shader = _bandShader(theme, backdrop));

    _drawText(
      canvas,
      _Copy.wordmark,
      topCenter: Offset(w / 2, h * 0.045),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.075,
        fontWeight: FontWeight.w800,
        fontVariations: const [ui.FontVariation('wght', 800)],
        color: theme.onBand,
        letterSpacing: w * 0.016,
        height: 1.0,
      ),
      maxWidth: w - margin * 2,
    );

    // The card holds the headline and the code, so the code always sits on
    // pure white no matter how saturated the background is.
    final cardTop = h * 0.135;
    final cardBottom = h - h * 0.115;
    final cardRect = Rect.fromLTRB(margin, cardTop, w - margin, cardBottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, Radius.circular(w * 0.055)),
      Paint()..color = theme.card,
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
        color: theme.ink,
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
        color: theme.accent,
        height: 1.35,
      ),
      maxWidth: cardRect.width - inner * 2,
    );

    var bottom = cardBottom - inner * 0.9;
    bottom = _drawVehicleBlock(
      canvas,
      bottom: bottom,
      width: w,
      height: h,
      maxWidth: cardRect.width - inner * 2,
      plateHeight: w * 0.108,
      theme: theme,
    );

    bottom = _drawTextUp(
      canvas,
      _Copy.subline,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.04,
        color: theme.mutedInk,
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
        color: theme.onBand,
        letterSpacing: w * 0.004,
      ),
      maxWidth: w - margin * 2,
    );
  }

  void _paintPlain(Canvas canvas, Size size, StickerTheme theme) {
    final w = size.width;
    final h = size.height;
    final margin = w * 0.07;
    final ink = theme.ink;

    _fillSheet(canvas, size, theme);

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
        color: theme.accent,
        height: 1.35,
      ),
      maxWidth: w - margin * 2,
    );

    y += h * 0.018;
    canvas.drawLine(
      Offset(margin, y),
      Offset(w - margin, y),
      Paint()
        ..color = theme.rule
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
        color: theme.accent,
        letterSpacing: w * 0.004,
      ),
      maxWidth: w - margin * 2,
    );

    // Stacked bottom-up, so the descriptor is drawn first to end up *under*
    // the plate — the same reading order the banner and panel layouts use.
    bottom -= h * 0.014;
    if (spec.descriptor.trim().isNotEmpty) {
      bottom = _drawTextUp(
        canvas,
        spec.descriptor.trim(),
        bottomCenter: Offset(w / 2, bottom),
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: w * 0.036,
          color: theme.mutedInk,
          height: 1.25,
        ),
        maxWidth: w - margin * 2,
      );
      bottom -= h * 0.006;
    }

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
      bottom -= h * 0.004;
    }

    bottom = _drawTextUp(
      canvas,
      _Copy.subline,
      bottomCenter: Offset(w / 2, bottom),
      style: TextStyle(
        fontFamily: AppFonts.text,
        fontSize: w * 0.042,
        color: theme.mutedInk,
        height: 1.3,
      ),
      maxWidth: w - margin * 2,
    );

    bottom -= h * 0.008;
    canvas.drawLine(
      Offset(margin, bottom),
      Offset(w - margin, bottom),
      Paint()
        ..color = theme.rule
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

  void _fillSheet(Canvas canvas, Size size, StickerTheme theme) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = theme.sheet,
    );
  }

  /// A flat ramp across [rect]. Tolerates a one-colour band so a theme can
  /// declare a solid field without repeating itself.
  Shader _bandShader(StickerTheme theme, Rect rect) {
    final colors = theme.band.length >= 2
        ? theme.band
        : <Color>[theme.band.first, theme.band.first];
    return LinearGradient(
      begin: theme.layout == StickerLayout.panel
          ? Alignment.topLeft
          : Alignment.centerLeft,
      end: theme.layout == StickerLayout.panel
          ? Alignment.bottomRight
          : Alignment.centerRight,
      colors: colors,
    ).createShader(rect);
  }

  /// Plate, then the vehicle descriptor beneath it, stacked upwards from
  /// [bottom]. Returns the top edge of whatever it drew.
  double _drawVehicleBlock(
    Canvas canvas, {
    required double bottom,
    required double width,
    required double height,
    required double maxWidth,
    required double plateHeight,
    required StickerTheme theme,
  }) {
    var top = bottom;

    if (spec.descriptor.trim().isNotEmpty) {
      top = _drawTextUp(
        canvas,
        spec.descriptor.trim(),
        bottomCenter: Offset(width / 2, top),
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: width * 0.036,
          color: theme.mutedInk,
          height: 1.25,
        ),
        maxWidth: maxWidth,
      );
      top -= height * 0.008;
    }

    if (spec.plate.trim().isNotEmpty) {
      _drawPlate(
        canvas,
        center: Offset(width / 2, top - plateHeight / 2),
        height: plateHeight,
        maxWidth: maxWidth,
      );
      top -= plateHeight + height * 0.014;
    }

    return top;
  }

  /// Paints the code centred in [available], on white, with a quiet zone.
  ///
  /// The quiet zone is not decoration. A QR needs clear white around it or the
  /// scanner cannot find its bounds, and on a windscreen — behind glass, at an
  /// angle, in glare — it is the first thing that fails. It is sized generously
  /// here and nothing is ever drawn inside it.
  ///
  /// Note what this method does *not* take: a theme. The tile is white and the
  /// modules are black on every design, including the ones with a tinted
  /// sheet. Themes colour the paper around the code, never the code.
  void _drawQrBlock(
    Canvas canvas, {
    required Rect available,
    required bool framed,
  }) {
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
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, codeSide, codeSide),
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      AvahanaaQrPainter(
        data: spec.qrData,
      ).paint(canvas, Size(codeSide, codeSide));
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

    final rect = Rect.fromCenter(center: center, width: width, height: height);
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
      maxLines: 1,
      ellipsis: '…',
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
  // A printed sticker must never ship a logo-less code just because the app
  // happened to export before the asset finished decoding. Unlike the on-screen
  // preview, this one waits.
  await AvahanaaQr.loadLogo();

  final height = (width / kStickerAspectRatio).round();
  final size = Size(width.toDouble(), height.toDouble());

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & size);

  // Paper is the theme's sheet colour even where a style does not paint to the
  // edge, so a transparent PNG never reaches a printer.
  canvas.drawRect(Offset.zero & size, Paint()..color = spec.theme.sheet);
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
