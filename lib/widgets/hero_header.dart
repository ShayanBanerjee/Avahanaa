import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'metal.dart';

/// The brand surface used by the home, profile and auth headers.
///
/// The design system fixes the gradient at primary → success. Rendered as a
/// flat two-stop it reads cheap at this size, so it is built as a metal ramp
/// ([MetalPalette.brand]) that still starts at primary and ends on the success
/// green — same gradient, machined. Two soft radial glows sit over it for a
/// light source, and a specular band sweeps across on entrance.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xxl,
    ),
    this.borderRadius,
    this.palette = MetalPalette.brand,
    this.sheen = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final MetalPalette palette;

  /// Set false for surfaces where a moving highlight would compete with the
  /// content — panic-mode banners, for instance.
  final bool sheen;

  @override
  Widget build(BuildContext context) {
    final surface = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.gradient()),
        child: Stack(
          children: [
            // Highlight — gives the top-left corner a light source.
            Positioned(
              left: -80,
              top: -110,
              child: _Glow(
                size: 280,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            // Vignette — anchors the bottom-right so the green does not float.
            Positioned(
              right: -70,
              bottom: -120,
              child: _Glow(
                size: 260,
                color: AppColors.primaryDeep.withValues(alpha: 0.42),
              ),
            ),
            // A hairline of light along the top edge, so the surface reads as
            // milled rather than printed.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1,
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    return sheen ? SheenSweep(child: surface) : surface;
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// A compact glass panel for placing on top of [HeroSurface].
class HeroGlassPanel extends StatelessWidget {
  const HeroGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
