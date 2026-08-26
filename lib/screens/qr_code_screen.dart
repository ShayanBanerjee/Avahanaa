import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/qr_payload_builder.dart';
import '../utils/sticker_renderer.dart';
import '../utils/sticker_sheet.dart';
import '../widgets/metal.dart';
import '../widgets/ui_kit.dart';

/// The sticker studio.
///
/// Two decisions live here and they are deliberately separate:
///
/// 1. **What the sticker looks like** — one of [StickerStyle], previewed at
///    full size by the same [StickerPainter] that writes the print file, so
///    there is no way for what the owner approves to differ from what comes
///    out of the printer.
/// 2. **How it lands on paper** — paper size and how many copies share a
///    sheet. That is laid out by [SheetPlan], and the page preview on this
///    screen is drawn from the very same plan the PDF is built from.
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
  SheetPaper _paper = SheetPaper.a4;
  int _copies = 1;

  bool _isExporting = false;
  bool _isPrinting = false;

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

  String get _fileStem {
    final plate = widget.vehicle.licensePlate.trim();
    return 'avahanaa-sticker-'
        '${plate.isEmpty ? 'vehicle' : plate.toUpperCase()}-${_style.name}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final shareableLink = QrPayloadBuilder.buildShareableLink(
      user: widget.user,
      vehicle: widget.vehicle,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studioTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _isExporting ? null : _shareSticker,
            tooltip: l10n.studioShareImage,
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
              child: _buildPrintCard(),
            ),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 180),
              child: _buildImageCard(shareableLink),
            ),
            const SizedBox(height: AppSpacing.xl),

            EntranceFade(
              delay: const Duration(milliseconds: 220),
              child: _buildPrintingTipsCard(),
            ),
            const SizedBox(height: AppSpacing.lg),

            EntranceFade(
              delay: const Duration(milliseconds: 260),
              child: _buildScanTipCard(),
            ),
          ],
        ),
      ),
    );
  }

  // -- Preview ------------------------------------------------------------

  Widget _buildPreview() {
    final l10n = AppL10n.of(context);
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
              color: _style.theme.sheet,
              borderRadius: AppRadius.heroAll,
              boxShadow: AppShadows.hero,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.heroAll,
              child: Semantics(
                label: l10n.studioPreviewOf(
                  _style.labelIn(l10n),
                  widget.vehicle.licensePlate,
                ),
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

  // -- Design -------------------------------------------------------------

  Widget _buildStylePicker() {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(overline: l10n.studioChooseALook, title: l10n.studioStickerDesign),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _style.theme.floodsInk
                  ? Icons.water_drop_rounded
                  : Icons.check_circle_rounded,
              size: 16,
              color: _style.theme.floodsInk
                  ? AppColors.warning
                  : AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _style.descriptionIn(l10n),
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -- Paper --------------------------------------------------------------

  Widget _buildPrintCard() {
    final l10n = AppL10n.of(context);
    final plan = SheetPlan.compute(pageSize: _paper.sizePt, copies: _copies);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          overline: l10n.studioPutItOnPaper,
          title: l10n.studioPrintASheet,
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OptionRail<SheetPaper>(
                label: l10n.studioPaper,
                values: SheetPaper.values,
                selected: _paper,
                labelOf: (paper) => paper.label,
                onSelect: (paper) => setState(() => _paper = paper),
              ),
              const SizedBox(height: AppSpacing.md),
              _OptionRail<int>(
                label: l10n.studioPerSheet,
                values: kSheetCopyOptions,
                selected: _copies,
                labelOf: (copies) => '$copies',
                onSelect: (copies) => setState(() => _copies = copies),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetPreview(paper: _paper, plan: plan, spec: _spec),
              const SizedBox(height: AppSpacing.md),
              Text(
                _sheetCaption(plan),
                textAlign: TextAlign.center,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (plan.isBelowScanFloor) ...[
                const SizedBox(height: AppSpacing.md),
                _ScanFloorWarning(),
              ],
              const SizedBox(height: AppSpacing.lg),
              MetalButton(
                label: _isPrinting ? l10n.studioPreparing : l10n.studioPrintThisSheet,
                icon: Icons.print_rounded,
                busy: _isPrinting,
                onPressed: _printSheet,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _sharePdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(l10n.studioSendPdf),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _sheetCaption(SheetPlan plan) {
    final l10n = AppL10n.of(context);
    if (plan.slots.isEmpty) return l10n.studioPaperTooSmall;
    final mm = plan.stickerSizeMm;
    final each = plan.copies == 1 ? 'sticker' : 'stickers';
    return '${plan.copies} $each on one ${_paper.label} sheet · '
        '${mm.width.round()} × ${mm.height.round()} mm each · '
        '${_paper.description}';
  }

  // -- Image --------------------------------------------------------------

  Widget _buildImageCard(String shareableLink) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          overline: l10n.studioOrSendPicture,
          title: l10n.studioShareTheImage,
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OptionRail<StickerSize>(
                label: 'Size',
                values: StickerSize.values,
                selected: _size,
                labelOf: (size) => size.label,
                onSelect: (size) => setState(() => _size = size),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _size.description,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _shareSticker,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(
                    _isExporting ? l10n.studioPreparing : l10n.studioShareOrSave,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: TextButton.icon(
                  onPressed: () => _copyToClipboard(shareableLink),
                  icon: const Icon(Icons.link_rounded),
                  label: Text(l10n.studioCopyScanLink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -- Cards --------------------------------------------------------------

  Widget _buildPrintingTipsCard() {
    final l10n = AppL10n.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(overline: l10n.studioMakeItLast, title: l10n.studioGettingItPrinted),
          NumberedStep(
            number: '1',
            title: l10n.studioPrintFullSize,
            detail:
                'Turn off "fit to page" or "shrink to fit". The sheet is '
                'already sized for the paper you picked.',
          ),
          NumberedStep(
            number: '2',
            title: l10n.studioCutAtMarks,
            detail: l10n.studioCutAtMarksBody,
          ),
          NumberedStep(
            number: '3',
            title: l10n.studioLaminate,
            detail: l10n.studioLaminateBody,
          ),
          NumberedStep(
            number: '4',
            title: l10n.studioFixInside,
            detail: l10n.studioFixInsideBody,
            accent: AppColors.success,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildScanTipCard() {
    final l10n = AppL10n.of(context);
    return AppCard(
      color: AppColors.infoSurface,
      borderColor: AppColors.infoBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBadge(
            icon: Icons.center_focus_strong_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.studioAnyoneCanScan, style: AppText.titleMedium),
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
    final l10n = AppL10n.of(context);
    Clipboard.setData(ClipboardData(text: text));
    showAppSnackBar(
      ScaffoldMessenger.of(context),
      l10n.studioScanLinkCopied,
      kind: AppSnackKind.success,
    );
  }

  Future<void> _printSheet() async {
    final l10n = AppL10n.of(context);
    // Captured before the first await — the widget may be gone afterwards.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isPrinting = true);

    try {
      await printStickerSheet(
        spec: _spec,
        paper: _paper,
        copies: _copies,
        jobName: _fileStem,
      );
    } catch (_) {
      showAppSnackBar(
        messenger,
        l10n.studioPrinterFailed,
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _sharePdf() async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isPrinting = true);

    try {
      await shareStickerSheetPdf(
        spec: _spec,
        paper: _paper,
        copies: _copies,
        filename: '$_fileStem-${_paper.label.toLowerCase()}.pdf',
      );
    } catch (_) {
      showAppSnackBar(
        messenger,
        l10n.studioPdfFailed,
        kind: AppSnackKind.error,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _shareSticker() async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);

    try {
      final bytes = await renderStickerPng(_spec, width: _size.pixelWidth);
      if (bytes == null) {
        _showExportError(messenger);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$_fileStem.png');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: l10n.studioShareText,
          subject: l10n.studioShareSubject,
        ),
      );
    } catch (_) {
      _showExportError(messenger);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportError(ScaffoldMessengerState messenger) {
    final l10n = AppL10n.of(context);
    showAppSnackBar(
      messenger,
      l10n.studioImageFailed,
      kind: AppSnackKind.error,
    );
  }
}

/// Shown when the chosen sheet would print a code too small to scan through a
/// windscreen. A warning, not a block — a small spare for the glovebox is a
/// perfectly good reason to ignore it.
class _ScanFloorWarning extends StatelessWidget {
  const _ScanFloorWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: AppRadius.controlAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This small a sticker is hard to scan from outside the car. '
              'Fewer per sheet, or bigger paper, reads better through glass.',
              style: AppText.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet preview
// ---------------------------------------------------------------------------

/// The page, as it will come out of the printer.
///
/// Built from the same [SheetPlan] the PDF is, so the arrangement on screen is
/// the arrangement on paper — including the margin, which is the part people
/// are surprised by.
class _SheetPreview extends StatelessWidget {
  const _SheetPreview({
    required this.paper,
    required this.plan,
    required this.spec,
  });

  final SheetPaper paper;
  final SheetPlan plan;
  final StickerSpec spec;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${plan.copies} ${plan.copies == 1 ? 'sticker' : 'stickers'} '
          'on a ${paper.label} sheet',
      image: true,
      child: SizedBox(
        height: 260,
        child: Center(
          child: AspectRatio(
            aspectRatio: paper.widthPt / paper.heightPt,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderStrong),
                boxShadow: AppShadows.card,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / paper.widthPt;
                  return Stack(
                    children: [
                      for (final slot in plan.slots)
                        Positioned(
                          left: slot.left * scale,
                          top: slot.top * scale,
                          width: slot.width * scale,
                          height: slot.height * scale,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: StickerPainter(spec: spec),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
    final l10n = AppL10n.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${style.labelIn(l10n)}. ${style.descriptionIn(l10n)}',
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
                          color: style.theme.sheet,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          // Each chip paints a complete sticker, QR included.
                          // Eight of them scroll in a row, so each gets its own
                          // layer — otherwise scrolling repaints all eight.
                          child: RepaintBoundary(
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
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        style.labelIn(l10n),
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
                      Icon(
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

/// A labelled row of mutually exclusive options.
///
/// Generic because the studio now picks three different things this way —
/// paper, copies per sheet and image size — and three hand-rolled segmented
/// controls would drift apart.
class _OptionRail<T> extends StatelessWidget {
  const _OptionRail({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          child: Text(label.toUpperCase(), style: AppText.overline),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.controlAll,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  for (final value in values)
                    Expanded(
                      child: _OptionButton(
                        label: labelOf(value),
                        isSelected: value == selected,
                        onTap: () => onSelect(value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.controlAll,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            constraints: const BoxConstraints(minHeight: 42),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: AppRadius.controlAll,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected ? AppShadows.card : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryDeep
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
