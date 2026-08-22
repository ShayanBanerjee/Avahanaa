import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../theme/app_theme.dart';
import '../utils/qr_payload_builder.dart';
import '../widgets/qr_visual.dart';
import '../widgets/ui_kit.dart';
import 'home_screen.dart' show kQrHeroTag;

class QRCodeScreen extends StatelessWidget {
  final UserModel user;
  final VehicleModel vehicle;

  const QRCodeScreen({super.key, required this.user, required this.vehicle});

  static const double _shareQrImageSize = 600;
  static const String _qrTemplateAsset = 'assets/images/qr_template.svg';
  static const double _qrBoxWidthFactor = 0.42;
  static const double _qrBoxPaddingFactor = 0.06;
  static const double _qrBoxCornerRadiusFactor = 0.08;
  static const double _templateQrSlotTopFactor = 15.253906 / 240.749997;
  static const double _templateQrSlotSizeFactor = 70.125 / 147.75;
  static final Future<svg.PictureInfo> _templatePictureFuture =
      _loadTemplatePicture();

  @override
  Widget build(BuildContext context) {
    final qrPayload = QrPayloadBuilder.buildPayload(
      user: user,
      vehicle: vehicle,
    );
    final shareableLink = QrPayloadBuilder.buildShareableLink(
      user: user,
      vehicle: vehicle,
    );
    final carDescriptor = [
      vehicle.color,
      vehicle.carModel,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _shareQRCode(context, qrPayload),
            tooltip: 'Share sticker',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntranceFade(child: _buildStickerHero(qrPayload, carDescriptor)),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareQRCode(context, qrPayload),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share or save sticker'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context, shareableLink),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Copy scan link'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 140),
              child: _buildPrintingCard(),
            ),
            const SizedBox(height: AppSpacing.lg),

            EntranceFade(
              delay: const Duration(milliseconds: 200),
              child: _buildScanTipCard(),
            ),
          ],
        ),
      ),
    );
  }

  // -- Hero ---------------------------------------------------------------

  Widget _buildStickerHero(String qrPayload, String carDescriptor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.heroAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.hero,
      ),
      child: Column(
        children: [
          _buildQrPreview(qrPayload),
          const SizedBox(height: AppSpacing.lg),
          if (vehicle.licensePlate.trim().isNotEmpty)
            PlateBadge(plate: vehicle.licensePlate, height: 38),
          if (carDescriptor.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              carDescriptor,
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrintingCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(
            overline: 'Make it last',
            title: 'Printing your sticker',
          ),
          NumberedStep(
            number: '1',
            title: 'Share the image to yourself',
            detail: 'Send it to a print shop, or save it and print at home.',
          ),
          NumberedStep(
            number: '2',
            title: 'Print on plain white A5 paper',
            detail: 'Do not scale it down — the code needs its white margin.',
          ),
          NumberedStep(
            number: '3',
            title: 'Laminate it',
            detail: 'A clear sleeve works too. Bangalore sun fades ink fast.',
          ),
          NumberedStep(
            number: '4',
            title: 'Fix it inside the windshield',
            detail: 'Driver-side corner, code facing out, nothing covering it.',
            accent: AppColors.success,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildScanTipCard() {
    return AppCard(
      color: AppColors.infoSurface,
      borderColor: AppColors.infoBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconBadge(
            icon: Icons.center_focus_strong_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anyone can scan it', style: AppText.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'No app required — a phone camera or Google Lens is enough. '
                  'Keep the white border around the code clean and the sticker '
                  'flat, and it reads through glass at arm’s length.',
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Actions ------------------------------------------------------------

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      'Scan link copied',
      kind: AppSnackKind.success,
    );
  }

  Future<void> _shareQRCode(BuildContext context, String qrData) async {
    // Captured before the first await — the widget may be gone afterwards.
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pngBytes = await _buildQrPngBytes(qrData, _shareQrImageSize);
      if (pngBytes == null) {
        _showShareError(messenger);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/avahanaa-qr-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Scan this Avahanaa code to reach me about my vehicle.',
          subject: 'My Avahanaa QR sticker',
        ),
      );
    } catch (_) {
      _showShareError(messenger);
    }
  }

  void _showShareError(ScaffoldMessengerState messenger) {
    showAppSnackBar(
      messenger,
      'Could not share the sticker image.',
      kind: AppSnackKind.error,
    );
  }

  // -- QR rendering -------------------------------------------------------

  static Future<svg.PictureInfo> _loadTemplatePicture() {
    return svg.vg.loadPicture(const svg.SvgAssetLoader(_qrTemplateAsset), null);
  }

  Widget _buildQrPreview(String qrData) {
    return FutureBuilder<svg.PictureInfo>(
      future: _templatePictureFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildTemplateQr(qrData, snapshot.data!.size);
        }
        if (snapshot.hasError) {
          return _buildClassicQr(qrData);
        }
        return const AspectRatio(
          aspectRatio: 0.61,
          child: AppSkeleton(height: double.infinity, radius: AppRadius.hero),
        );
      },
    );
  }

  /// Fallback when the sticker artwork cannot be loaded.
  Widget _buildClassicQr(String qrData) {
    return Column(
      children: [
        Hero(
          tag: kQrHeroTag,
          child: AvahanaaQrView(data: qrData, size: 260),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Avahanaa', style: AppText.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Scan to alert the owner',
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTemplateQr(String qrData, Size templateSize) {
    final aspectRatio = templateSize.width / templateSize.height;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final qrBoxLayout = _buildQrBoxLayout(width: width, height: height);

            return Stack(
              children: [
                Positioned.fill(
                  child: svg.SvgPicture.asset(
                    _qrTemplateAsset,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: qrBoxLayout.left,
                  top: qrBoxLayout.top,
                  width: qrBoxLayout.size,
                  height: qrBoxLayout.size,
                  child: Hero(
                    tag: kQrHeroTag,
                    child: Container(
                      padding: EdgeInsets.all(qrBoxLayout.padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          qrBoxLayout.radius,
                        ),
                      ),
                      child: AvahanaaQrView(data: qrData),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -- PNG export ---------------------------------------------------------

  Future<List<int>?> _buildQrPngBytes(String data, double size) async {
    final templatePicture = await _loadTemplatePictureSafely();
    if (templatePicture != null) {
      return _buildTemplateQrBytes(data, templatePicture, size);
    }

    return _buildPlainQrBytes(data, size);
  }

  Future<svg.PictureInfo?> _loadTemplatePictureSafely() async {
    try {
      return await _templatePictureFuture;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>?> _buildPlainQrBytes(String data, double size) async {
    final painter = AvahanaaQr.painter(data);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);
    painter.paint(canvas, Size(size, size));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<List<int>?> _buildTemplateQrBytes(
    String data,
    svg.PictureInfo templatePicture,
    double maxWidth,
  ) async {
    final templateWidth = templatePicture.size.width;
    final templateHeight = templatePicture.size.height;
    final aspectRatio = templateWidth / templateHeight;
    final width = maxWidth;
    final height = width / aspectRatio;
    final qrBoxLayout = _buildQrBoxLayout(width: width, height: height);
    final qrSize = qrBoxLayout.size - (qrBoxLayout.padding * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    canvas.save();
    canvas.scale(width / templateWidth, height / templateHeight);
    canvas.drawPicture(templatePicture.picture);
    canvas.restore();

    final boxRect = Rect.fromLTWH(
      qrBoxLayout.left,
      qrBoxLayout.top,
      qrBoxLayout.size,
      qrBoxLayout.size,
    );
    final boxPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, Radius.circular(qrBoxLayout.radius)),
      boxPaint,
    );

    final painter = AvahanaaQr.painter(data);

    canvas.save();
    canvas.translate(
      qrBoxLayout.left + qrBoxLayout.padding,
      qrBoxLayout.top + qrBoxLayout.padding,
    );
    painter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.round(), height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  _QrBoxLayout _buildQrBoxLayout({
    required double width,
    required double height,
  }) {
    final qrBoxSize = width * _qrBoxWidthFactor;
    final qrSlotTop = height * _templateQrSlotTopFactor;
    final qrSlotSize = width * _templateQrSlotSizeFactor;
    final qrBoxTop = qrSlotTop + ((qrSlotSize - qrBoxSize) / 2);
    final qrBoxLeft = (width - qrBoxSize) / 2;
    final qrBoxPadding = qrBoxSize * _qrBoxPaddingFactor;
    final qrRadius = qrBoxSize * _qrBoxCornerRadiusFactor;

    return _QrBoxLayout(
      size: qrBoxSize,
      top: qrBoxTop,
      left: qrBoxLeft,
      padding: qrBoxPadding,
      radius: qrRadius,
    );
  }
}

class _QrBoxLayout {
  final double size;
  final double top;
  final double left;
  final double padding;
  final double radius;

  const _QrBoxLayout({
    required this.size,
    required this.top,
    required this.left,
    required this.padding,
    required this.radius,
  });
}
