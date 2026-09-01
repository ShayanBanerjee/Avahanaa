import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr/qr.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'metal.dart';
import 'ui_kit.dart';

/// The one place QR appearance is defined.
///
/// The on-screen preview, the printable sticker composite and the shared PNG
/// all render through [AvahanaaQrPainter], so the code a stranger scans is
/// pixel-identical in styling wherever it appears.
///
/// ## Why this is hand-painted
///
/// `qr_flutter` only offers square-or-circle modules. Circles are the usual way
/// to make a code "look designed", and they are the wrong trade here: a circle
/// inscribed in a square keeps 78.5% of its area, so every module loses a fifth
/// of its ink. That margin is exactly what a phone camera is working with
/// through a dusty windscreen at arm's length. Rounded squares at a 0.28 corner
/// radius keep ~97% of the area and read as just as deliberate, so this file
/// drives the module matrix from the `qr` package directly and draws it.
///
/// ## What is safe to style, and what is not
///
/// * **Module colour stays pure black on pure white.** A tinted or gradient
///   module lowers the contrast ratio the scanner's binarisation step depends
///   on, and that is the first thing to fail in the field.
/// * **Corner radius is free.** It changes the silhouette, not the coverage.
/// * **Finder eyes carry no data**, so their shape is the cheapest visual win
///   available, as long as the 1:1:3:1:1 ratio along the centre line survives.
///   A rounded frame preserves it exactly.
/// * **A centre logo costs redundancy**, and is paid for by the error
///   correction level below.
///
/// ## Error correction, measured rather than assumed
///
/// For the real payload (38 characters), module size on an A5 sticker:
///
/// * L: version 3, 29x29 modules, 2.81mm
/// * M: version 3, 29x29 modules, 2.81mm
/// * Q: version 4, 33x33 modules, 2.47mm
/// * H: version 5, 37x37 modules, 2.20mm
///
/// M is free, buying 15% redundancy over L at the same version. Q costs 12% of
/// the module size and buys 25%, which is what pays for the centre logo. H was
/// rejected: 22% smaller modules is a real loss at arm's length, and the logo
/// does not need that much headroom.
///
/// Raising the level does not change what the code *contains* — already-printed
/// stickers keep working, they simply carry different redundancy than newly
/// exported ones.
abstract final class AvahanaaQr {
  /// Q (25%). See the table above for why this and not H.
  static const int errorCorrectionLevel = QrErrorCorrectLevel.Q;

  /// The app-wide style. One definition, so preview and print cannot drift.
  static const QrStyle style = QrStyle();

  /// The brand mark drawn in the middle of the code, once loaded.
  ///
  /// Null until [loadLogo] completes, and every painter treats null as "draw no
  /// logo" — a code that has not finished loading its decoration is still a
  /// perfectly good code, so nothing ever waits on this.
  static ui.Image? logo;

  static Future<void>? _loading;

  /// Decodes the brand mark once, for the centre of the code.
  ///
  /// Safe to call repeatedly; the work happens on the first call only. Called
  /// from `main()` so the first frame already has it, and from the sticker
  /// export path so a PNG never ships a logo-less code by accident.
  static Future<void> loadLogo() {
    return _loading ??= () async {
      try {
        final data = await rootBundle.load('assets/images/logo.png');
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          // The mark is drawn at ~17% of the code; decoding the full 153KB
          // asset to paint it at 60px wastes memory on every sticker.
          targetWidth: 256,
        );
        final frame = await codec.getNextFrame();
        logo = frame.image;
      } catch (_) {
        // A missing or corrupt asset must never take the QR down with it.
        logo = null;
      }
    }();
  }
}

/// How a code is drawn. Geometry only — the colours are not negotiable.
@immutable
class QrStyle {
  const QrStyle({
    this.moduleRadius = 0.35,
    this.eyeOuterRadius = 0.10,
    this.eyeInnerRadius = 0.30,
    this.logoFraction = 0.17,
    this.logoPadding = 0.22,
  });

  /// Corner radius of a data module, as a fraction of the module size. 0 is a
  /// hard square, 0.5 is a circle.
  ///
  /// The cheapest knob on this class: the sweep decoded 10/10 at every value
  /// from 0 to 0.5, so the default is set for looks and still sits well inside
  /// what was measured. [kMaxSafeModuleRadius] is the guard.
  final double moduleRadius;

  /// Corner radius of the finder frame, as a fraction of its 7-module box.
  ///
  /// **This is the dangerous one.** The detector finds a code by scanning for
  /// the 1:1:3:1:1 ratio across a finder pattern, and rounding the frame
  /// distorts that ratio on the lines near its edges. The cliff is sharp and
  /// close:
  ///
  /// * 0.00 - 0.12: decodes 10/10 under the full degradation set
  /// * 0.16: 9/10 (loses the distant-scan case)
  /// * 0.20: 8/10
  /// * 0.24 and above: **0/10 — it stops decoding at all, even clean**
  ///
  /// The default keeps a margin below the last fully-passing value. Do not
  /// raise it because a mockup looks better; re-run the sweep.
  final double eyeOuterRadius;

  /// Corner radius of the pupil, as a fraction of its 3-module box.
  final double eyeInnerRadius;

  /// Width of the centre logo, as a fraction of the code width. The white pad
  /// behind it is what actually occludes data, so this is budgeted against the
  /// error correction level rather than chosen by eye.
  ///
  /// Measured: decodes 10/10 up to 0.24 and starts failing at 0.28. The logo
  /// turned out to be far cheaper than expected — it was never what broke the
  /// first attempt at styling this code.
  final double logoFraction;

  /// White margin around the logo, as a fraction of the logo width.
  final double logoPadding;

  /// Ceilings established by the sweep in `tool/verify_sticker_scan.py`. The
  /// unit test asserts the shipped style stays under them, so a "small tweak"
  /// cannot silently break every printed sticker.
  static const double kMaxSafeEyeOuterRadius = 0.12;
  static const double kMaxSafeModuleRadius = 0.50;
  static const double kMaxSafeLogoFraction = 0.24;

  /// The plainest possible code: hard squares, no logo. Kept because it is the
  /// control the scan harness measures every other style against.
  static const QrStyle plain = QrStyle(
    moduleRadius: 0,
    eyeOuterRadius: 0,
    eyeInnerRadius: 0,
    logoFraction: 0,
  );

  QrStyle copyWith({
    double? moduleRadius,
    double? eyeOuterRadius,
    double? eyeInnerRadius,
    double? logoFraction,
    double? logoPadding,
  }) {
    return QrStyle(
      moduleRadius: moduleRadius ?? this.moduleRadius,
      eyeOuterRadius: eyeOuterRadius ?? this.eyeOuterRadius,
      eyeInnerRadius: eyeInnerRadius ?? this.eyeInnerRadius,
      logoFraction: logoFraction ?? this.logoFraction,
      logoPadding: logoPadding ?? this.logoPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QrStyle &&
        other.moduleRadius == moduleRadius &&
        other.eyeOuterRadius == eyeOuterRadius &&
        other.eyeInnerRadius == eyeInnerRadius &&
        other.logoFraction == logoFraction &&
        other.logoPadding == logoPadding;
  }

  @override
  int get hashCode => Object.hash(
    moduleRadius,
    eyeOuterRadius,
    eyeInnerRadius,
    logoFraction,
    logoPadding,
  );
}

/// Builds (and caches) the module matrix for a payload.
///
/// `QrImage` trials all eight mask patterns to pick the best one, which is far
/// too much work to redo on every repaint — and the sticker studio paints nine
/// codes at once across its theme chips.
QrImage qrMatrixFor(String data, {int? errorCorrectionLevel}) {
  final level = errorCorrectionLevel ?? AvahanaaQr.errorCorrectionLevel;
  final key = '$level $data';
  final cached = _matrixCache[key];
  if (cached != null) return cached;

  final matrix = QrImage(QrCode.fromData(data: data, errorCorrectLevel: level));

  // Bounded so a long session cannot grow it without limit.
  if (_matrixCache.length > 24) _matrixCache.clear();
  _matrixCache[key] = matrix;
  return matrix;
}

final Map<String, QrImage> _matrixCache = <String, QrImage>{};

/// Draws the code. Pure black modules on pure white, always.
class AvahanaaQrPainter extends CustomPainter {
  AvahanaaQrPainter({
    required this.data,
    this.style = AvahanaaQr.style,
    this.errorCorrectionLevel,
    ui.Image? logo,
  }) : logo = logo ?? AvahanaaQr.logo;

  final String data;
  final QrStyle style;
  final int? errorCorrectionLevel;
  final ui.Image? logo;

  static const Color _ink = Color(0xFF000000);
  static const Color _paper = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;

    final matrix = qrMatrixFor(
      data,
      errorCorrectionLevel: errorCorrectionLevel,
    );
    final count = matrix.moduleCount;
    final module = side / count;

    canvas.drawRect(Rect.fromLTWH(0, 0, side, side), Paint()..color = _paper);

    final ink = Paint()
      ..color = _ink
      ..isAntiAlias = true;

    // Data modules, skipping the three finder patterns — those are drawn as
    // whole shapes below so their frames stay unbroken.
    final radius = Radius.circular(module * style.moduleRadius);
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (_isFinder(row, col, count)) continue;
        if (!matrix.isDark(row, col)) continue;

        final rect = Rect.fromLTWH(col * module, row * module, module, module);
        if (style.moduleRadius <= 0) {
          canvas.drawRect(rect, ink);
        } else {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), ink);
        }
      }
    }

    _drawEye(canvas, ink, Offset.zero, module);
    _drawEye(canvas, ink, Offset((count - 7) * module, 0), module);
    _drawEye(canvas, ink, Offset(0, (count - 7) * module), module);

    _drawLogo(canvas, side);
  }

  /// True inside any of the three 7x7 finder patterns.
  bool _isFinder(int row, int col, int count) {
    final top = row < 7;
    final bottom = row >= count - 7;
    final left = col < 7;
    final right = col >= count - 7;
    return (top && left) || (top && right) || (bottom && left);
  }

  /// A finder pattern: 7x7 frame one module thick, with a 3x3 pupil.
  ///
  /// Drawn as three nested shapes rather than as modules so the frame reads as
  /// a continuous stroke. The 1:1:3:1:1 ratio along the centre line — which is
  /// what the detector actually looks for — is preserved exactly.
  void _drawEye(Canvas canvas, Paint ink, Offset origin, double module) {
    final outer = Rect.fromLTWH(origin.dx, origin.dy, module * 7, module * 7);
    final middle = outer.deflate(module);
    final inner = outer.deflate(module * 2);

    if (style.eyeOuterRadius <= 0) {
      canvas.drawRect(outer, ink);
      canvas.drawRect(middle, Paint()..color = _paper);
      canvas.drawRect(inner, ink);
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        outer,
        Radius.circular(outer.width * style.eyeOuterRadius),
      ),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        middle,
        Radius.circular(middle.width * style.eyeOuterRadius * 0.82),
      ),
      Paint()..color = _paper,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        inner,
        Radius.circular(inner.width * style.eyeInnerRadius),
      ),
      ink,
    );
  }

  void _drawLogo(Canvas canvas, double side) {
    final image = logo;
    if (image == null || style.logoFraction <= 0) return;

    final logoSide = side * style.logoFraction;
    final pad = logoSide * style.logoPadding;
    final centre = Offset(side / 2, side / 2);

    // The white pad is the part that actually occludes data, so it is kept as
    // tight as it can be while still giving the mark a clean edge.
    final padded = Rect.fromCenter(
      center: centre,
      width: logoSide + pad * 2,
      height: logoSide + pad * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(padded, Radius.circular(padded.width * 0.22)),
      Paint()..color = _paper,
    );

    final target = Rect.fromCenter(
      center: centre,
      width: logoSide,
      height: logoSide,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(target, Radius.circular(target.width * 0.24)),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      target,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AvahanaaQrPainter old) {
    return old.data != data ||
        old.style != style ||
        old.errorCorrectionLevel != errorCorrectionLevel ||
        old.logo != logo;
  }
}

/// The canonical QR widget.
class AvahanaaQrView extends StatelessWidget {
  const AvahanaaQrView({
    super.key,
    required this.data,
    this.size,
    this.style = AvahanaaQr.style,
  });

  final String data;
  final double? size;
  final QrStyle style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Semantics(
      label: l10n.qrSemanticLabel,
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: size == null ? Size.infinite : Size.square(size!),
          painter: AvahanaaQrPainter(data: data, style: style),
          isComplex: true,
          willChange: false,
        ),
      ),
    );
  }
}

/// Rasterises a code on its own, for callers that need pixels rather than a
/// widget.
Future<Uint8List?> renderQrPng(String data, {int width = 600}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  AvahanaaQrPainter(
    data: data,
  ).paint(canvas, Size(width.toDouble(), width.toDouble()));
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(width, width);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  } finally {
    picture.dispose();
  }
}

/// The QR presented as a hero object.
///
/// The code sits on pure white inside a machined bezel, framed by scanner
/// corner brackets, with a status ring breathing behind it while it is live.
/// Every one of those treatments stays *outside* the quiet zone — the bezel is
/// the jewellery, the code underneath is untouched black on white.
class QrHeroPlinth extends StatelessWidget {
  const QrHeroPlinth({
    super.key,
    required this.data,
    required this.isActive,
    this.size = 200,
  });

  final String data;
  final bool isActive;
  final double size;

  @override
  Widget build(BuildContext context) {
    // The reticle is a *scanner affordance* — "point a camera here" — not a
    // status readout. The status is already on the pill beside it, in words.
    //
    // It used to be success green, which put a third saturated colour on a
    // screen that is otherwise graphite and bronze, and spent the one colour
    // reserved for "somebody is on their way" on decoration. Bronze when the
    // code is live, muted when it is paused: the same information, in the
    // brand's own accent.
    final accent = isActive ? AppColors.primary : AppColors.textTertiary;

    // Bezel: a machined graphite ring around a recessed white well.
    //
    // The ring is dark on purpose. An earlier silver version vanished against
    // the white card behind it — a near-white metal ramp has nothing to shade
    // against, so it read as haze rather than as an edge.
    //
    // The well's padding is sized as a fraction of the code, not a fixed
    // number: the QR spec wants at least four modules of clear white around
    // the symbol, and at 180px that is ~28px, well over the 16px a standard
    // card inset would have given it.
    final quietZone = size * 0.16;

    final code = Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: AppRadius.heroAll,
        gradient: MetalPalette.graphite.gradient(),
        boxShadow: Metal.lift(MetalPalette.graphite.depth),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(quietZone),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.hero - 7),
          // Inner shade at the top edge makes the well read as recessed into
          // the metal rather than sitting on top of it.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 5,
              spreadRadius: -1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AvahanaaQrView(data: data, size: size),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // The ring sits behind the plinth and reads as a "live" indicator.
        //
        // Wrapped in a RepaintBoundary because it never stops animating.
        // Without one, every frame of a slow decorative pulse repaints the
        // whole plinth above it — the bezel, the reticle, and a QR made of
        // several hundred rounded rects.
        if (isActive)
          RepaintBoundary(
            child: BreathingRing(color: accent, size: size + 96),
          )
        else
          const SizedBox.shrink(),
        ReticleFrame(
          color: accent,
          gap: 13,
          length: 26,
          thickness: 3,
          child: SheenSweep(intensity: 0.10, child: code),
        ),
      ],
    );
  }
}

/// A soft radial halo that expands and fades on a slow loop.
class BreathingRing extends StatefulWidget {
  const BreathingRing({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<BreathingRing> createState() => _BreathingRingState();
}

class _BreathingRingState extends State<BreathingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = AppMotion.entrance.transform(_controller.value);
          return Container(
            width: widget.size * (0.82 + 0.18 * t),
            height: widget.size * (0.82 + 0.18 * t),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.0),
                  widget.color.withValues(alpha: 0.14 * (1 - t)),
                  widget.color.withValues(alpha: 0.0),
                ],
                stops: const [0.55, 0.82, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The panel
// ---------------------------------------------------------------------------

/// One action under the QR panel.
@immutable
class QrPanelAction {
  const QrPanelAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

/// The QR presented as the centrepiece of a screen.
///
/// [QrHeroPlinth] is the object; this is the case it sits in. A rail across
/// the top says what the code is and whether it is live, the plinth stands in
/// a recessed well, the vehicle it belongs to is named underneath, and the
/// things you can do with it sit on a separate shelf at the bottom.
///
/// The separation matters: the well is quiet and pale so the black-on-white
/// code is the highest-contrast thing on the screen, and the actions are
/// visually below the object rather than floating over it, so nothing competes
/// with the code for the eye.
class QrShowcasePanel extends StatelessWidget {
  const QrShowcasePanel({
    super.key,
    required this.data,
    required this.isActive,
    this.plate = '',
    this.descriptor = '',
    this.title,
    this.codeSize = 176,
    this.actions = const <QrPanelAction>[],
    this.onTap,
  });

  final String data;
  final bool isActive;
  final String plate;
  final String descriptor;

  /// Null means "use the default heading", which has to be resolved against a
  /// context — it is translated, and a default parameter value cannot be.
  final String? title;
  final double codeSize;
  final List<QrPanelAction> actions;

  /// Opens the sticker studio. The whole plinth is the target.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Green stays here: this one *is* a status readout — the showcase panel's
    // whole job is to say whether the code is live or paused — and that is
    // exactly what the success token is reserved for.
    final accent = isActive ? AppColors.success : AppColors.warning;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.heroAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.hero,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.heroAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Rail(
              title: title ?? AppL10n.of(context).qrYourWindshieldCode,
              isActive: isActive,
              accent: accent,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  _Well(
                    onTap: onTap,
                    child: QrHeroPlinth(
                      data: data,
                      isActive: isActive,
                      size: codeSize,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Identity(plate: plate, descriptor: descriptor),
                ],
              ),
            ),
            if (actions.isNotEmpty) _Shelf(actions: actions),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.title,
    required this.isActive,
    required this.accent,
  });

  final String title;
  final bool isActive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.qrScanToAlertMe, style: AppText.overline),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: isActive ? l10n.commonLive : l10n.qrPaused,
            color: accent,
            icon: isActive
                ? Icons.shield_rounded
                : Icons.pause_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}

/// The recessed stage the plinth stands on.
class _Well extends StatelessWidget {
  const _Well({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stage = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.heroAll,
        border: Border.all(color: AppColors.border),
        // A pale vertical wash, lit from the top, so the plinth reads as
        // standing in the well rather than pasted onto it.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceMuted, AppColors.background],
        ),
      ),
      child: Center(child: child),
    );

    if (onTap == null) return stage;

    return PressableScale(
      scale: 0.985,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.heroAll,
          child: stage,
        ),
      ),
    );
  }
}

/// Plate and vehicle description, under the code.
class _Identity extends StatelessWidget {
  const _Identity({required this.plate, required this.descriptor});

  final String plate;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    final hasPlate = plate.trim().isNotEmpty;
    final hasDescriptor = descriptor.trim().isNotEmpty;
    if (!hasPlate && !hasDescriptor) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasPlate) PlateBadge(plate: plate, height: 36),
        if (hasPlate && hasDescriptor) const SizedBox(height: AppSpacing.sm),
        if (hasDescriptor)
          Text(
            descriptor.trim(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

/// The action shelf. Sits on its own tinted band under a hairline, so it reads
/// as a set of controls rather than as more of the card.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.actions});

  final List<QrPanelAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              SizedBox(
                height: 28,
                child: VerticalDivider(width: 1, color: AppColors.border),
              ),
            Expanded(child: _ShelfButton(action: actions[i])),
          ],
        ],
      ),
    );
  }
}

class _ShelfButton extends StatelessWidget {
  const _ShelfButton({required this.action});

  final QrPanelAction action;

  @override
  Widget build(BuildContext context) {
    final enabled = action.onPressed != null;
    final colour = enabled ? AppColors.primary : AppColors.textTertiary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, size: 18, color: colour),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelMedium.copyWith(color: colour),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
