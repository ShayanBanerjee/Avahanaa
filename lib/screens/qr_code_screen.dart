import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../theme/app_theme.dart';
import '../utils/qr_payload_builder.dart';
import '../utils/sticker_renderer.dart';
import '../widgets/metal.dart';
import '../widgets/ui_kit.dart';

/// The sticker studio.
///
/// The owner picks a design, sees it exactly as it will print, and exports it.
/// The preview is a `CustomPaint` driven by [StickerPainter] — the same painter
/// [renderStickerPng] replays into the exported file — so there is no way for
/// what they approve here to differ from what comes out of the printer.
class QRCodeScreen extends StatefulWidget {
  final UserModel user;
  final VehicleModel vehicle;

  const QRCodeScreen({super.key, required this.user, required this.vehicle});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  StickerStyle _style = StickerStyle.signature;
  StickerSize _size = StickerSize.print;
  bool _isExporting = false;

  StickerSpec get _spec => StickerSpec(
    qrData: QrPayloadBuilder.buildPayload(
      user: widget.user,
      vehicle: widget.vehicle,
    ),
    plate: widget.vehicle.licensePlate,
    descriptor: [
      widget.vehicle.color,
      widget.vehicle.carModel,
    ].where((part) => part.trim().isNotEmpty).join(' '),
    style: _style,
  );

  @override
  Widget build(BuildContext context) {
    final shareableLink = QrPayloadBuilder.buildShareableLink(
      user: widget.user,
      vehicle: widget.vehicle,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your sticker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _isExporting ? null : _shareSticker,
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
            EntranceFade(child: _buildPreview()),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 60),
              child: _buildStylePicker(),
            ),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 120),
              child: _buildSizePicker(),
            ),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MetalButton(
                    label: _isExporting
                        ? 'Preparing…'
                        : 'Share or save sticker',
                    icon: Icons.ios_share_rounded,
                    busy: _isExporting,
                    onPressed: _shareSticker,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(shareableLink),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Copy scan link'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 200),
              child: _buildPrintingCard(),
            ),
            const SizedBox(height: AppSpacing.lg),

            EntranceFade(
              delay: const Duration(milliseconds: 240),
              child: _buildScanTipCard(),
            ),
          ],
        ),
      ),
    );
  }

  // -- Preview ------------------------------------------------------------

  Widget _buildPreview() {
    return Center(
      child: ConstrainedBox(
        // A tall sticker on a tall phone would otherwise push the controls
        // entirely below the fold.
        constraints: const BoxConstraints(maxWidth: 300),
        child: AspectRatio(
          aspectRatio: kStickerAspectRatio,
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.emphasis,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.heroAll,
              boxShadow: AppShadows.hero,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.heroAll,
              child: Semantics(
                label:
                    'Preview of your ${_style.label} sticker for '
                    '${widget.vehicle.licensePlate}',
                image: true,
                child: CustomPaint(
                  painter: StickerPainter(spec: _spec),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Pickers ------------------------------------------------------------

  Widget _buildStylePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(overline: 'Choose a look', title: 'Sticker design'),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: StickerStyle.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final style = StickerStyle.values[index];
              return _StyleChip(
                style: style,
                spec: _spec,
                isSelected: style == _style,
                onTap: () => setState(() => _style = style),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _style.description,
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSizePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(overline: 'Export', title: 'Image size'),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Row(
            children: [
              for (final size in StickerSize.values)
                Expanded(
                  child: _SizeOption(
                    size: size,
                    isSelected: size == _size,
                    onTap: () => setState(() => _size = size),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _size.description,
          style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // -- Cards --------------------------------------------------------------

  Widget _buildPrintingCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(overline: 'Make it last', title: 'Getting it printed'),
          NumberedStep(
            number: '1',
            title: 'Share the image to yourself',
            detail: 'Send it to a print shop, or save it and print at home.',
          ),
          NumberedStep(
            number: '2',
            title: 'Print at A5 on plain white paper',
            detail:
                'The image is already A-sized, so print it at 100% — do not '
                'scale it down.',
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      'Scan link copied',
      kind: AppSnackKind.success,
    );
  }

  Future<void> _shareSticker() async {
    // Captured before the first await — the widget may be gone afterwards.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);

    try {
      final bytes = await renderStickerPng(
        _spec,
        width: _size.pixelWidth,
      );
      if (bytes == null) {
        _showExportError(messenger);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final plate = widget.vehicle.licensePlate.trim().isEmpty
          ? 'vehicle'
          : widget.vehicle.licensePlate.trim().toUpperCase();
      final file = File(
        '${tempDir.path}/avahanaa-sticker-$plate-${_style.name}.png',
      );
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'Scan this Avahanaa code to reach me about my vehicle.',
          subject: 'My Avahanaa QR sticker',
        ),
      );
    } catch (_) {
      _showExportError(messenger);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportError(ScaffoldMessengerState messenger) {
    showAppSnackBar(
      messenger,
      'Could not create the sticker image.',
      kind: AppSnackKind.error,
    );
  }
}

// ---------------------------------------------------------------------------
// Picker controls
// ---------------------------------------------------------------------------

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.spec,
    required this.isSelected,
    required this.onTap,
  });

  final StickerStyle style;
  final StickerSpec spec;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${style.label} design. ${style.description}',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? AppColors.primaryTint : AppColors.surface,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: 104,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // A real miniature of the design, painted by the same painter
                // that produces the print file. An abstract icon cannot tell
                // you what you are about to print.
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: kStickerAspectRatio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CustomPaint(
                            painter: StickerPainter(
                              spec: spec.copyWith(style: style),
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        style.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.primaryDeep
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeOption extends StatelessWidget {
  const _SizeOption({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final StickerSize size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${size.label} size. ${size.description}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: AppRadius.controlAll,
            ),
            child: Text(
              size.label,
              style: AppText.labelMedium.copyWith(
                color: isSelected ? AppColors.onDark : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
