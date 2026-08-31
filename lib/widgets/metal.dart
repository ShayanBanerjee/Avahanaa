/// The metallic layer of the Avahanaa design system.
///
/// "Metallic" here means light behaving like light on a machined surface, not
/// skeuomorphic chrome. Three things do the work, and nothing else:
///
/// 1. **An asymmetric gradient.** Flat fills read as plastic. Real metal has a
///    bright band where the light source hits and a fast falloff after it, so
///    the ramps below are deliberately uneven rather than a smooth two-stop.
/// 2. **A bevel.** One hairline of white along the top edge and one of black
///    along the bottom is enough to imply a milled edge catching light.
/// 3. **A sheen that moves.** Metal only reads as metal when the highlight
///    travels. [SheenSweep] passes a specular band across a surface once on
///    entrance, then rarely.
///
/// Deliberately **not** metallic, and these are hard limits:
///
/// * **QR modules.** Pure black on pure white. A gradient across a finder
///   pattern destroys the contrast a scanner's binarisation step depends on.
/// * **Panic-mode text.** An alert is read by someone walking fast toward their
///   car. Flat, maximum-contrast fills only.
/// * **Body copy.** Text sits on solid ground, never on a moving highlight.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Palettes
// ---------------------------------------------------------------------------

/// A five-stop metal ramp: lift, base, core shadow, depth, and a final catch of
/// light at the far edge.
@immutable
class MetalPalette {
  const MetalPalette({
    required this.lift,
    required this.base,
    required this.core,
    required this.depth,
    required this.catchLight,
  });

  final Color lift;
  final Color base;
  final Color core;
  final Color depth;
  final Color catchLight;

  List<Color> get colors => <Color>[lift, base, core, depth, catchLight];

  /// Uneven on purpose — an even spread reads as plastic.
  static const List<double> stops = <double>[0.0, 0.28, 0.52, 0.82, 1.0];

  LinearGradient gradient({
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(begin: begin, end: end, colors: colors, stops: stops);
  }

  /// Brand blue as anodised steel, running to a deep teal catch-light.
  ///
  /// Deepened and desaturated (Aug 2026). The previous ramp ran a bright
  /// `#2563EB` to a bright `#10B981`, which is the most generic gradient on
  /// the internet — every generated landing page has it, and it made a product
  /// that has survived Play review look like a weekend template. The hue
  /// journey is the same, so the brand is still recognisably itself; it just
  /// stops shouting. Contrast improved as a side effect: worst stop went from
  /// 4.62:1 to 5.78:1 against white.
  ///
  /// `AppPrint.heroGradient` carries the flat three-stop version of this same
  /// ramp, so the sticker on the windscreen and the hero in the app are the
  /// same object.
  ///
  /// Every stop is clamped so white body text on it clears WCAG AA (4.5:1).
  /// The literal token values would not: `#5B95F7` gives 2.96:1 and the raw
  /// success green `#10B981` gives 2.54:1, and the home hero puts muted white
  /// copy across both. Measured, not eyeballed — see the ramp audit in
  /// `test/contrast_test.dart`.
  static const MetalPalette brand = MetalPalette(
    lift: Color(0xFF1B5FD4),
    base: Color(0xFF1F4FB8),
    core: Color(0xFF193F96),
    depth: Color(0xFF122A66),
    catchLight: Color(0xFF0E5E52),
  );

  /// Brushed silver, for the registration plate.
  static const MetalPalette silver = MetalPalette(
    lift: Color(0xFFFFFFFF),
    base: Color(0xFFF4F6F9),
    core: Color(0xFFE2E6EC),
    depth: Color(0xFFD3D9E2),
    catchLight: Color(0xFFF7F9FC),
  );

  /// Graphite, for dark chrome — the QR bezel.
  ///
  /// The only palette here that follows the theme, and for a reason the others
  /// do not share: it is *chrome*, not identity. The brand ramp, the alert
  /// banner, the plate and the success surface all represent something fixed —
  /// a brand, an emergency, a physical number plate — so they look the same at
  /// midnight as at noon. A bezel is just a housing, and a dark housing on a
  /// dark ground disappears.
  static MetalPalette get graphite =>
      AppColors.isDark ? _graphiteDark : _graphiteLight;

  static const MetalPalette _graphiteLight = MetalPalette(
    lift: Color(0xFF4A5464),
    base: Color(0xFF2E3644),
    core: Color(0xFF212836),
    depth: Color(0xFF161C27),
    catchLight: Color(0xFF39424F),
  );

  /// Lifted, so the bezel still reads as a raised housing rather than a hole.
  static const MetalPalette _graphiteDark = MetalPalette(
    lift: Color(0xFF39434F),
    base: Color(0xFF242C38),
    core: Color(0xFF1A202B),
    depth: Color(0xFF11161F),
    catchLight: Color(0xFF2B3440),
  );

  /// A near-flat ramp for ordinary card surfaces.
  ///
  /// This exists so the metallic treatment stops being five special cases. It
  /// is deliberately almost imperceptible — a card is a place to read body
  /// copy, and copy sits on solid ground. What it buys is that light falls the
  /// same way across every surface in the app, which is the difference between
  /// a design system and a set of screens that were styled separately.
  static MetalPalette get slate =>
      AppColors.isDark ? _slateDark : _slateLight;

  static const MetalPalette _slateLight = MetalPalette(
    lift: Color(0xFFFFFFFF),
    base: Color(0xFFFDFDFE),
    core: Color(0xFFF9FAFC),
    depth: Color(0xFFF4F7FA),
    catchLight: Color(0xFFFBFCFE),
  );

  static const MetalPalette _slateDark = MetalPalette(
    lift: Color(0xFF1B2536),
    base: Color(0xFF17202F),
    core: Color(0xFF141C2A),
    depth: Color(0xFF111826),
    catchLight: Color(0xFF19222F),
  );

  /// Escalation red, machined. Used only by panic-mode surfaces, where the
  /// gradient stays shallow so contrast never drops.
  static const MetalPalette alert = MetalPalette(
    lift: Color(0xFFD91F35),
    base: Color(0xFFC81B30),
    core: Color(0xFFB01829),
    depth: Color(0xFF8A1220),
    catchLight: Color(0xFFBE1A2D),
  );

  /// Deep anodised green. Much darker than the raw success token because the
  /// verify-email screen sets white body copy directly on it, and no green
  /// light enough to read as "success green" can carry white text at 4.5:1.
  static const MetalPalette success = MetalPalette(
    lift: Color(0xFF18865F),
    base: Color(0xFF0B845C),
    core: Color(0xFF077353),
    depth: Color(0xFF045C43),
    catchLight: Color(0xFF138660),
  );
}

// ---------------------------------------------------------------------------
// Decoration
// ---------------------------------------------------------------------------

abstract final class Metal {
  /// A milled-edge surface: metal ramp plus depth.
  ///
  /// The bevel is **not** part of this decoration, and that is not a
  /// simplification — it is a correctness requirement. A `BoxDecoration`
  /// cannot carry a `borderRadius` together with a `Border` whose sides are
  /// different colours; Flutter asserts "a borderRadius can only be given on
  /// borders with uniform colors" during paint, and the whole subtree stops
  /// painting. Every rounded metal surface in this app is exactly that case,
  /// so a top-white/bottom-black `Border` here silently blanks the control it
  /// is meant to decorate.
  ///
  /// The bevel is drawn by [BevelHighlight] instead, stacked inside the
  /// surface's clip, where it can follow the corner radius exactly.
  static BoxDecoration surface(
    MetalPalette palette, {
    BorderRadius? radius,
    List<BoxShadow>? shadows,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      borderRadius: radius,
      gradient: palette.gradient(begin: begin, end: end),
      boxShadow: shadows,
    );
  }

  /// Depth beneath a raised metal control.
  static List<BoxShadow> lift(Color tone) => <BoxShadow>[
    BoxShadow(
      color: tone.withValues(alpha: 0.34),
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: -4,
    ),
    const BoxShadow(
      color: Color(0x14101828),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}

/// The milled edge: a hairline of light along the top of a surface and a band
/// of shade along the bottom.
///
/// Drawn as an overlay rather than as a [Border] so it can sit inside a clip
/// and follow the corner radius exactly — and, critically, so the surface
/// underneath can keep its `borderRadius`. A `Border` with different colours
/// top and bottom is illegal on a rounded `BoxDecoration` and aborts the paint
/// (see [Metal.surface]).
class BevelHighlight extends StatelessWidget {
  const BevelHighlight({
    super.key,
    this.radius = AppRadius.card,
    this.opacity = 0.34,
    this.shade = 0.20,
  });

  final double radius;

  /// Strength of the light along the top edge.
  final double opacity;

  /// Strength of the shade along the bottom edge. Zero for a surface that
  /// should read as lit but not raised.
  final double shade;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.42],
              ),
            ),
          ),
          if (shade > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: shade),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.30],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------

/// Passes a specular band across its child.
///
/// Runs once shortly after entrance, then repeats on a long interval. A
/// continuously shimmering surface stops reading as premium and starts reading
/// as a loading state, so the pause is the point.
class SheenSweep extends StatefulWidget {
  const SheenSweep({
    super.key,
    required this.child,
    this.interval = AppMotion.ambientRest,
    this.intensity = 0.22,
    this.angle = 0.36,
  });

  final Widget child;
  final Duration interval;
  final double intensity;

  /// Tilt of the band, in radians.
  final double angle;

  @override
  State<SheenSweep> createState() => _SheenSweepState();
}

class _SheenSweepState extends State<SheenSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.ambient,
  );

  @override
  void initState() {
    super.initState();
    _schedule(AppMotion.slow);
  }

  void _schedule(Duration delay) {
    Future<void>.delayed(delay, () async {
      if (!mounted) return;
      await _controller.forward(from: 0);
      if (!mounted) return;
      _controller.reset();
      _schedule(widget.interval);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.value == 0) {
                  return const SizedBox.shrink();
                }
                final t = AppMotion.ambientCurve.transform(_controller.value);
                // Travel from well before the surface to well past it, so the
                // band enters and leaves rather than fading in place.
                final x = -1.6 + 3.2 * t;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(x - 0.5, -1),
                      end: Alignment(x + 0.5, 1),
                      transform: GradientRotation(widget.angle),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: widget.intensity),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Press physics: a small, fast scale-down that settles on release.
///
/// Gives a control the sense of being pushed into its housing. Kept subtle —
/// 3% — because anything larger reads as a toy.
///
/// Uses [Listener] rather than a gesture recogniser, so it observes pointer
/// events without competing for them. That lets it wrap an `InkWell` and give
/// scale *and* ripple, instead of one swallowing the other.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.entrance,
        child: widget.child,
      ),
    );
  }
}

/// Counts up to [value] when it changes.
///
/// Used on the home stat tiles so a number that has just changed announces
/// itself instead of silently swapping. Tabular figures keep it from jittering.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.duration = AppMotion.slow,
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$value', style: style, maxLines: 1);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: AppMotion.emphasis,
      builder: (context, v, _) => Text(
        '${v.round()}',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Four corner brackets, like a scanner reticle framing a target.
///
/// Wrapped around the QR on screen. It reinforces "point a camera at this"
/// without touching the code itself — the brackets sit outside the quiet zone.
class ReticleFrame extends StatelessWidget {
  ReticleFrame({
    super.key,
    required this.child,
    Color? color,
    this.length = 22,
    this.thickness = 2.5,
    this.gap = 14,
  }) : color = color ?? AppColors.primary;

  final Widget child;
  final Color color;
  final double length;
  final double thickness;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ReticlePainter(
                color: color,
                length: length,
                thickness: thickness,
                inset: -gap,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({
    required this.color,
    required this.length,
    required this.thickness,
    required this.inset,
  });

  final Color color;
  final double length;
  final double thickness;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final r = Rect.fromLTWH(0, 0, size.width, size.height).deflate(inset);
    final l = math.min(length, math.min(r.width, r.height) / 3);

    void corner(Offset c, double dx, double dy) {
      canvas.drawLine(c, c.translate(dx * l, 0), paint);
      canvas.drawLine(c, c.translate(0, dy * l), paint);
    }

    corner(r.topLeft, 1, 1);
    corner(r.topRight, -1, 1);
    corner(r.bottomLeft, 1, -1);
    corner(r.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter old) {
    return old.color != color ||
        old.length != length ||
        old.thickness != thickness ||
        old.inset != inset;
  }
}

/// The primary action, as a machined button.
///
/// Exists because a gradient cannot be expressed through `ElevatedButton`'s
/// `backgroundColor`. Everything else — height, radius, label style, the 48dp
/// minimum target — matches the themed button exactly, so the two can sit on
/// the same screen without looking like different systems.
class MetalButton extends StatelessWidget {
  const MetalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.palette = MetalPalette.brand,
    this.height = 56,
    this.busy = false,
    this.foreground = AppColors.onDark,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MetalPalette palette;
  final double height;
  final bool busy;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: enabled ? 1 : 0.55,
          child: Container(
            height: height,
            decoration: Metal.surface(
              palette,
              radius: AppRadius.controlAll,
              shadows: enabled ? Metal.lift(palette.core) : null,
            ),
            clipBehavior: Clip.antiAlias,
            // The InkWell wraps the label rather than sitting beside it in the
            // stack, so every pixel of the button is one hit target and the
            // ripple cannot be swallowed by the content above it.
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                splashColor: Colors.white.withValues(alpha: 0.18),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: BevelHighlight(radius: AppRadius.control),
                    ),
                    Center(
                      child: busy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  foreground,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icon != null) ...[
                                  Icon(icon, size: 20, color: foreground),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.labelLarge.copyWith(
                                      color: foreground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
