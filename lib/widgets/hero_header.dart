import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The brand gradient surface used by the home and profile headers.
///
/// The design system fixes the gradient at primary → success. Flat, that reads
/// cheap at this size, so two soft radial glows are layered over it: a white
/// highlight top-left and a deep-blue vignette bottom-right. The result has
/// depth while still being, unambiguously, the same gradient as the splash.
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
    this.colors = AppColors.heroGradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
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
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
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
