import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import 'metal.dart';
import 'ui_kit.dart';

/// The one place QR appearance is defined.
///
/// The on-screen preview, the printable sticker composite and the shared PNG
/// all read these constants, so the code a stranger scans is byte-identical in
/// styling wherever it is rendered.
///
/// Scan reliability outranks aesthetics here, always:
///
/// * **Pure black modules and eyes.** The eyes were previously tinted brand
///   blue. A tinted finder pattern lowers the contrast ratio the scanner's
///   binarisation step depends on, and through a dusty windscreen that is
///   exactly the margin you lose first.
/// * **Error correction M, not L.** The payload is a short URL, so the density
///   cost is one QR version. In exchange roughly 15% of the code can be
///   obscured by dirt, a wiper smear or a crease and still decode.
///
/// Raising the correction level does not change what the code *contains* —
/// already-printed stickers keep working, they simply carry less redundancy
/// than newly exported ones.
abstract final class AvahanaaQr {
  static const int errorCorrectionLevel = QrErrorCorrectLevel.M;

  static const QrEyeStyle eyeStyle = QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: Colors.black,
  );

  static const QrDataModuleStyle moduleStyle = QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.square,
    color: Colors.black,
  );

  /// A painter configured identically to [AvahanaaQrView], for canvas export.
  static QrPainter painter(String data) {
    return QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: errorCorrectionLevel,
      gapless: true,
      eyeStyle: eyeStyle,
      dataModuleStyle: moduleStyle,
    );
  }
}

/// The canonical QR widget.
class AvahanaaQrView extends StatelessWidget {
  const AvahanaaQrView({
    super.key,
    required this.data,
    this.size,
    this.padding = EdgeInsets.zero,
  });

  final String data;
  final double? size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'QR code for your vehicle',
      image: true,
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        padding: padding,
        backgroundColor: Colors.white,
        errorCorrectionLevel: AvahanaaQr.errorCorrectionLevel,
        gapless: true,
        eyeStyle: AvahanaaQr.eyeStyle,
        dataModuleStyle: AvahanaaQr.moduleStyle,
      ),
    );
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
    final accent = isActive ? AppColors.success : AppColors.textTertiary;

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
        if (isActive)
          BreathingRing(color: accent, size: size + 96)
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
          final t = Curves.easeOut.transform(_controller.value);
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
    this.title = 'Your windshield code',
    this.codeSize = 176,
    this.actions = const <QrPanelAction>[],
    this.onTap,
  });

  final String data;
  final bool isActive;
  final String plate;
  final String descriptor;
  final String title;
  final double codeSize;
  final List<QrPanelAction> actions;

  /// Opens the sticker studio. The whole plinth is the target.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            _Rail(title: title, isActive: isActive, accent: accent),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
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
                Text('SCAN TO ALERT ME', style: AppText.overline),
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
            label: isActive ? 'LIVE' : 'PAUSED',
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
        gradient: const LinearGradient(
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              const SizedBox(
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
