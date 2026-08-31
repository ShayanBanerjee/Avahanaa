/// Shared building blocks for every Avahanaa screen.
///
/// Screens compose these rather than hand-rolling containers, so a change to
/// the card treatment or the empty-state grammar lands everywhere at once.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'metal.dart';

// ---------------------------------------------------------------------------
// Motion
// ---------------------------------------------------------------------------

/// Fades and lifts its child into place once, on first build.
///
/// Used to stagger a column of cards so a screen assembles itself instead of
/// snapping in. Never applied to panic-mode surfaces — an alert must be
/// readable on frame one.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;

  /// Vertical distance travelled, in logical pixels.
  final double offset;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the platform "reduce motion" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.entrance,
    );

    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - curved.value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// A slow, continuous breathing scale — signals "this is live" without
/// demanding attention. Used on the QR status ring.
class BreathingPulse extends StatefulWidget {
  const BreathingPulse({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.06,
    this.duration = const Duration(milliseconds: 2600), // shimmer cycle
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<BreathingPulse> createState() => _BreathingPulseState();
}

class _BreathingPulseState extends State<BreathingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

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

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = AppMotion.ambientCurve.transform(_controller.value);
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------

/// The standard Avahanaa card: white, radius 16, flat, hairline border.
class AppCard extends StatelessWidget {
  AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    Color? color,
    Color? borderColor,
    this.onTap,
    this.shadows = AppShadows.card,
    this.clip = false,
  }) : borderColor = borderColor ?? AppColors.border, color = color ?? AppColors.surface;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow> shadows;

  /// Set when the child paints to the card edge (e.g. a gradient banner).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    // A card whose colour was not overridden gets the near-flat `slate` ramp
    // rather than a single fill. It is almost imperceptible on its own — what
    // it buys is that light falls the same way here as it does on the hero,
    // the QR bezel and the plate, so the metallic treatment reads as one
    // system instead of four special cases.
    //
    // An explicit colour still wins outright: tinted cards (info, alert,
    // success) mean something, and a ramp across them would only muddy it.
    final usesDefaultSurface = color == AppColors.surface;

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: usesDefaultSurface ? null : color,
        gradient: usesDefaultSurface
            ? MetalPalette.slate.gradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        borderRadius: AppRadius.cardAll,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: onTap == null
                  ? Padding(padding: padding, child: child)
                  : InkWell(
                      onTap: onTap,
                      child: Padding(padding: padding, child: child),
                    ),
            ),
            // One hairline of light along the top edge. This is the whole
            // difference between a filled rectangle and a milled one.
            if (usesDefaultSurface)
              Positioned.fill(
                child: IgnorePointer(
                  child: BevelHighlight(
                    radius: AppRadius.card,
                    // Much quieter than on a saturated metal surface. A card
                    // is a place to read, not a thing to admire.
                    opacity: AppColors.isDark ? 0.06 : 0.55,
                    shade: AppColors.isDark ? 0.10 : 0.04,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final surface = clip
        ? ClipRRect(borderRadius: AppRadius.cardAll, child: decorated)
        : decorated;

    // Only interactive cards get press physics; a static card that shrinks
    // under a stray finger reads as broken.
    return onTap == null ? surface : PressableScale(child: surface);
  }
}

/// A section label above a group of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.action,
  });

  final String title;
  final String? overline;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(overline!.toUpperCase(), style: AppText.overline),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(title, style: AppText.headlineMedium),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Icon in a tinted rounded square — the leading element of most rows.
class AppIconBadge extends StatelessWidget {
  AppIconBadge({
    super.key,
    required this.icon,
    Color? color,
    this.size = 44,
    this.iconSize = 22,
  }) : color = color ?? AppColors.primary;

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// A tappable settings/navigation row.
class AppListRow extends StatelessWidget {
  AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    Color? iconColor,
    Color? titleColor,
    this.trailing,
    this.onTap,
  }) : titleColor = titleColor ?? AppColors.textPrimary, iconColor = iconColor ?? AppColors.primary;

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // 48dp minimum tap target is satisfied by the badge height + padding.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              AppIconBadge(icon: icon, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.titleSmall.copyWith(color: titleColor),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Status chip. Always pairs colour with an icon and a word — never colour
/// alone, per the accessibility rules.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onDark = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.onDark : color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.28)
              : color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.labelSmall.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// An Indian registration plate, rendered as the physical object.
///
/// Private vehicles in India carry black characters on a white plate with a
/// blue "IND" band. Showing the plate this way makes the app feel like it is
/// about *this* car rather than about a database row.
///
/// A real plate is stamped metal, so this is the one place in the app where
/// the metallic treatment is not a stylistic choice — it is what the object
/// actually is. The face carries a brushed-silver ramp and the characters are
/// embossed with a light shadow above and a highlight below.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.plate, this.height = 40});

  /// Physical-plate colours, not brand colours — these deliberately do not
  /// track the theme, because a real Indian plate does not either.
  static const Color _plateInk = Color(0xFF111827);
  static const Color _indBand = Color(0xFF1E3A8A);

  final String plate;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = plate.trim().toUpperCase();
    if (value.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'Registration number ${value.split('').join(' ')}',
      excludeSemantics: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _plateInk, width: 1.5),
          boxShadow: AppShadows.card,
          gradient: MetalPalette.silver.gradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The blue IND band.
            Container(
              width: height * 0.42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B4FA8), _indBand, Color(0xFF16296B)],
                  stops: [0.0, 0.45, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.5),
                  bottomLeft: Radius.circular(4.5),
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'IND',
                style: AppText.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: height * 0.18,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: height * 0.22),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppText.plate.copyWith(
                      fontSize: height * 0.42,
                      color: _plateInk,
                      letterSpacing: height * 0.045,
                      // Emboss: shade above, catch-light below.
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          offset: const Offset(0, -0.6),
                          blurRadius: 0.5,
                        ),
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.85),
                          offset: const Offset(0, 0.9),
                          blurRadius: 0.6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single number-plus-label metric.
class AppStatTile extends StatelessWidget {
  AppStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    Color? color,
  }) : color = color ?? AppColors.primary;

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconBadge(icon: icon, color: color, size: 36, iconSize: 18),
          const SizedBox(height: AppSpacing.md),
          // Numeric values count up so a figure that just changed announces
          // itself; non-numeric ones ("On"/"Off") render directly.
          switch (int.tryParse(value)) {
            final int n => AnimatedCounter(
              value: n,
              style: AppText.metric.copyWith(color: color),
            ),
            _ => Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.metric.copyWith(color: color),
            ),
          },
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

/// Empty states always say what is missing, why it matters, and what fixes it.
class AppEmptyState extends StatelessWidget {
  AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    Color? accent,
  }) : accent = accent ?? AppColors.primary;

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: EntranceFade(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.16),
                      accent.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Icon(icon, size: 42, color: accent),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmering placeholder used while Firestore streams settle. Showing the
/// shape of the content that is coming reads faster than a bare spinner.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = AppRadius.card,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: [
                AppColors.surfaceMuted,
                Color(0xFFE9EDF2),
                AppColors.surfaceMuted,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback
// ---------------------------------------------------------------------------

enum AppSnackKind { neutral, success, error }

/// One snackbar grammar for the whole app: icon + message, colour by kind.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  AppSnackKind kind = AppSnackKind.neutral,
}) {
  final (Color background, IconData icon) = switch (kind) {
    AppSnackKind.success => (AppColors.successDark, Icons.check_circle_rounded),
    AppSnackKind.error => (AppColors.alert, Icons.error_rounded),
    AppSnackKind.neutral => (AppColors.textPrimary, Icons.info_rounded),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          children: [
            Icon(icon, color: AppColors.onDark, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppText.bodyMedium.copyWith(color: AppColors.onDark),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Drag handle for bottom sheets.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Numbered step used by the "how it works" and printing instruction lists.
class NumberedStep extends StatelessWidget {
  NumberedStep({
    super.key,
    required this.number,
    required this.title,
    this.detail,
    Color? accent,
    this.isLast = false,
  }) : accent = accent ?? AppColors.primary;

  final String number;
  final String title;
  final String? detail;
  final Color accent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(accent),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: AppText.labelSmall.copyWith(color: AppColors.onDark),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: accent.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 3,
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.titleSmall),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
