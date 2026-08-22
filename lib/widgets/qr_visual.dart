import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';

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

/// The QR presented as a hero object: a white plinth with a status ring that
/// breathes while the code is live.
class QrHeroPlinth extends StatelessWidget {
  const QrHeroPlinth({
    super.key,
    required this.data,
    required this.isActive,
    this.size = 200,
    this.heroTag,
  });

  final String data;
  final bool isActive;
  final double size;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final accent = isActive ? AppColors.success : AppColors.textTertiary;

    Widget code = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.heroAll,
        border: Border.all(color: AppColors.border),
      ),
      child: AvahanaaQrView(data: data, size: size),
    );

    if (heroTag != null) {
      code = Hero(
        tag: heroTag!,
        // Keep the QR crisp mid-flight rather than letting it stretch.
        flightShuttleBuilder: (_, _, _, _, _) => code,
        child: code,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // The ring sits behind the plinth and reads as a "live" indicator.
        if (isActive)
          BreathingRing(color: accent, size: size + 96)
        else
          const SizedBox.shrink(),
        code,
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
