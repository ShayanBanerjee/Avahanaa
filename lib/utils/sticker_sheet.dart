/// Composes printable sheets from a single sticker design.
///
/// The sticker itself is one A-ratio tile ([StickerPainter]). Getting it onto
/// paper is a separate problem, and the one this file solves: how many tiles
/// fit on the page the owner actually has, where exactly they sit, and where
/// to cut.
///
/// Nothing here is fixed at build time. [SheetPlan.compute] takes the page
/// dimensions it is handed and works out the grid, so the same code serves the
/// in-app preview and whatever page the print framework asks for.
///
/// Note what that does *not* buy on Android — see [printStickerSheet].
///
/// The layout maths is deliberately free of any `pdf` types so the on-screen
/// preview and the print file consume the same numbers.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'sticker_renderer.dart';

/// PostScript points per inch. PDF's native unit.
const double _pointsPerInch = 72;

/// Paper sizes offered in the app.
///
/// The dimensions are the page in points, portrait. A-series is what a
/// Bangalore print shop stocks; Letter is here for anyone printing at an
/// office abroad.
enum SheetPaper {
  a4(595.28, 841.89, 'A4', 'The default sheet at any print shop'),
  a5(419.53, 595.28, 'A5', 'Half of A4 — one sticker fills it'),
  a6(297.64, 419.53, 'A6', 'Postcard size — a small windscreen tile'),
  letter(612, 792, 'Letter', 'US office paper');

  const SheetPaper(this.widthPt, this.heightPt, this.label, this.description);

  final double widthPt;
  final double heightPt;
  final String label;
  final String description;

  Size get sizePt => Size(widthPt, heightPt);
}

/// How many stickers to put on one sheet.
///
/// Anything above 4 on A4 crosses the size below which the code stops reading
/// through a windscreen at arm's length, so the list stops there.
const List<int> kSheetCopyOptions = <int>[1, 2, 4];

/// Where every sticker sits on one page, in points from the top-left.
@immutable
class SheetPlan {
  const SheetPlan({
    required this.pageSize,
    required this.slots,
    required this.columns,
    required this.rows,
    required this.margin,
  });

  final Size pageSize;

  /// One rect per sticker, already A-ratio and centred in its cell.
  final List<Rect> slots;

  final int columns;
  final int rows;
  final double margin;

  int get copies => slots.length;

  /// Long edge of a single printed sticker, in millimetres. Shown to the owner
  /// because "A6" means nothing at the counter but "105 x 148 mm" does.
  Size get stickerSizeMm {
    if (slots.isEmpty) return Size.zero;
    final r = slots.first;
    return Size(
      r.width / _pointsPerInch * 25.4,
      r.height / _pointsPerInch * 25.4,
    );
  }

  /// Below this printed width the code stops reading at arm's length through
  /// a windscreen.
  ///
  /// The code occupies roughly half the sticker's width once the quiet zone
  /// and the surrounding copy are accounted for, so a 90mm sticker carries a
  /// ~45mm symbol — about the floor for a phone camera held a metre away,
  /// through glass, at an angle. Small paper with several copies on it drops
  /// under this fast: four to an A5 sheet gives a 65mm sticker.
  static const double scanFloorMm = 90;

  /// True when the sheet would print stickers too small to scan reliably.
  /// Surfaced in the studio rather than blocked — someone printing a spare for
  /// a glovebox has every right to a small one.
  bool get isBelowScanFloor =>
      slots.isNotEmpty && stickerSizeMm.width < scanFloorMm;

  /// Chooses the grid that prints the largest possible sticker.
  ///
  /// Every factorisation of [copies] is tried rather than assuming a square
  /// grid: on a portrait page two A-ratio tiles stack, four tile 2x2, and the
  /// wrong guess wastes a third of the paper.
  static SheetPlan compute({required Size pageSize, required int copies}) {
    final count = math.max(1, copies);
    final margin = (math.min(pageSize.width, pageSize.height) * 0.045).clamp(
      8.0,
      24.0,
    );
    final gutter = margin * 0.6;

    final usableWidth = pageSize.width - margin * 2;
    final usableHeight = pageSize.height - margin * 2;

    var bestColumns = 1;
    var bestRows = count;
    var bestWidth = 0.0;

    for (var columns = 1; columns <= count; columns++) {
      if (count % columns != 0) continue;
      final rows = count ~/ columns;

      final cellWidth = (usableWidth - gutter * (columns - 1)) / columns;
      final cellHeight = (usableHeight - gutter * (rows - 1)) / rows;
      if (cellWidth <= 0 || cellHeight <= 0) continue;

      final stickerWidth = math.min(
        cellWidth,
        cellHeight * kStickerAspectRatio,
      );

      // Ties go to the taller grid: two stacked tiles need one straight cut,
      // two side-by-side need one too, but stacking keeps the reading
      // direction of the sheet.
      if (stickerWidth > bestWidth + 0.01) {
        bestWidth = stickerWidth;
        bestColumns = columns;
        bestRows = rows;
      }
    }

    if (bestWidth <= 0) {
      return SheetPlan(
        pageSize: pageSize,
        slots: const <Rect>[],
        columns: 0,
        rows: 0,
        margin: margin,
      );
    }

    final cellWidth = (usableWidth - gutter * (bestColumns - 1)) / bestColumns;
    final cellHeight = (usableHeight - gutter * (bestRows - 1)) / bestRows;
    final stickerHeight = bestWidth / kStickerAspectRatio;

    final slots = <Rect>[];
    for (var row = 0; row < bestRows; row++) {
      for (var column = 0; column < bestColumns; column++) {
        final cellLeft = margin + column * (cellWidth + gutter);
        final cellTop = margin + row * (cellHeight + gutter);
        slots.add(
          Rect.fromLTWH(
            cellLeft + (cellWidth - bestWidth) / 2,
            cellTop + (cellHeight - stickerHeight) / 2,
            bestWidth,
            stickerHeight,
          ),
        );
      }
    }

    return SheetPlan(
      pageSize: pageSize,
      slots: slots,
      columns: bestColumns,
      rows: bestRows,
      margin: margin,
    );
  }
}

// ---------------------------------------------------------------------------
// PDF
// ---------------------------------------------------------------------------

/// Width, in pixels, of the single rasterised tile every sheet is built from.
///
/// Sized so the largest slot we ever produce — a 1-up A4 tile at ~538pt — is a
/// true 300dpi print master. Every smaller slot is oversampled. See
/// [renderPrintTile] for why it is one fixed size rather than per-slot.
const int _printTilePixels = 2250;

/// Rasterises the sticker at a resolution good for any sheet we can produce.
///
/// **This must be called while the app is in the foreground.**
/// [renderStickerPng] goes through `Picture.toImage()`, which needs the
/// engine's raster thread. Once the system print dialog is up the Flutter
/// activity is paused, that thread stops servicing work, and the future never
/// completes — the print preview hangs on "Preparing preview…" forever. The
/// first layout succeeds and every re-layout after it wedges, which is exactly
/// the case that matters: re-layout is what happens when someone changes the
/// paper or the orientation in the dialog.
///
/// So the tile is rendered once, up front, and the same bytes are stamped into
/// every re-layout. That is also why [buildStickerSheetPdf] accepts a
/// [stickerPng]: with one supplied, everything it does is pure Dart, and it
/// stays safe to call from inside `onLayout`.
///
/// One fixed size covers every sheet. The widest slot we ever produce is a
/// 1-up A4 tile (~538pt), so [_printTilePixels] is ~270dpi there and higher on
/// anything smaller. The code is pure black on white and the scan harness
/// decodes it down at 360px, so resampling into a smaller slot costs nothing
/// that matters.
Future<Uint8List?> renderPrintTile(StickerSpec spec) =>
    renderStickerPng(spec, width: _printTilePixels);

/// Builds a one-page PDF holding [copies] of [spec], laid out for [format].
///
/// Pass [stickerPng] from [renderPrintTile] whenever this might run while the
/// app is backgrounded — see that function for why. Without it the tile is
/// rasterised here, which is fine for a foreground one-shot export.
///
/// Returns the PDF bytes. The tile is stamped into every slot, so the file
/// stays the same size regardless of the copy count.
Future<Uint8List> buildStickerSheetPdf({
  required StickerSpec spec,
  required PdfPageFormat format,
  int copies = 1,
  bool cropMarks = true,
  Uint8List? stickerPng,
}) async {
  final pageSize = Size(format.width, format.height);
  final plan = SheetPlan.compute(pageSize: pageSize, copies: copies);

  final png = stickerPng ?? await renderPrintTile(spec);
  final document = pw.Document(
    title: 'Avahanaa sticker',
    author: 'Avahanaa',
    subject: 'Scan-to-alert windscreen sticker',
  );

  if (png == null) {
    // Nothing to place. Emit an empty page rather than throwing, so the caller
    // can still show a print dialog and fail visibly instead of silently.
    document.addPage(pw.Page(pageFormat: format, build: (_) => pw.SizedBox()));
    return document.save();
  }

  final image = pw.MemoryImage(png);

  document.addPage(
    pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: <pw.Widget>[
            for (final slot in plan.slots) ...<pw.Widget>[
              pw.Positioned(
                left: slot.left,
                top: slot.top,
                child: pw.SizedBox(
                  width: slot.width,
                  height: slot.height,
                  child: pw.Image(image, fit: pw.BoxFit.fill),
                ),
              ),
              if (cropMarks) ..._cropMarks(slot),
            ],
            if (plan.slots.isNotEmpty)
              pw.Positioned(
                left: plan.margin,
                top: pageSize.height - plan.margin * 0.85,
                child: pw.Text(
                  _footer(plan),
                  style: const pw.TextStyle(
                    fontSize: 6,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  return document.save();
}

String _footer(SheetPlan plan) {
  final size = plan.stickerSizeMm;
  final w = size.width.round();
  final h = size.height.round();
  final each = plan.copies == 1 ? 'sticker' : 'stickers';
  // ASCII only: the footer is set in the PDF's built-in Helvetica, which
  // carries no Unicode. A stray middot renders as a warning and a blank glyph.
  return 'avahanaa.com  |  ${plan.copies} $each  |  $w x $h mm  |  '
      'print at 100% (no fit-to-page), then cut at the marks';
}

/// Four L-shaped ticks just outside [slot], so the cut line is unambiguous
/// without drawing anything across the sticker.
List<pw.Widget> _cropMarks(Rect slot) {
  const length = 9.0;
  const offset = 3.0;
  const thickness = 0.4;
  const colour = PdfColors.grey500;

  pw.Widget horizontal(double left, double top) => pw.Positioned(
    left: left,
    top: top,
    child: pw.Container(width: length, height: thickness, color: colour),
  );
  pw.Widget vertical(double left, double top) => pw.Positioned(
    left: left,
    top: top,
    child: pw.Container(width: thickness, height: length, color: colour),
  );

  return <pw.Widget>[
    horizontal(slot.left - offset - length, slot.top),
    vertical(slot.left, slot.top - offset - length),
    horizontal(slot.right + offset, slot.top),
    vertical(slot.right, slot.top - offset - length),
    horizontal(slot.left - offset - length, slot.bottom),
    vertical(slot.left, slot.bottom + offset),
    horizontal(slot.right + offset, slot.bottom),
    vertical(slot.right, slot.bottom + offset),
  ];
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

PdfPageFormat pdfFormatFor(SheetPaper paper) =>
    PdfPageFormat(paper.widthPt, paper.heightPt);

/// Hands the sheet to the platform print dialog.
///
/// The sheet is built inside `onLayout` from the format the framework reports,
/// so the page we hand over always matches the paper that was asked for.
///
/// **Paper and copies-per-sheet are chosen in the app, not in this dialog.**
/// `printing` 5.14.3 forwards Android's `onLayout` to Dart exactly once, at
/// job start; changing the paper or orientation inside the system dialog never
/// reaches us, and the spooler then sits on "Preparing preview…" waiting for a
/// layout result nobody will send. Verified on an API 37 emulator: the first
/// layout logs and completes, the second never fires.
///
/// So [dynamicLayout] is declared false — the document we produce is fixed for
/// the format we were given. That is also why the studio puts the paper and
/// per-sheet pickers on its own screen, with a preview, rather than leaning on
/// the system dialog to offer them. Newer `printing` releases are not an
/// option here: 5.15.0 pulls `xml ^7`, which `flutter_local_notifications`
/// cannot coexist with, and that package carries the alert path.
///
/// Returns false when the user dismisses the dialog.
Future<bool> printStickerSheet({
  required StickerSpec spec,
  required SheetPaper paper,
  int copies = 1,
  String? jobName,
}) async {
  // Rasterised here, before the dialog takes the foreground, because it cannot
  // be done once the dialog is up. See [renderPrintTile].
  final tile = await renderPrintTile(spec);

  return Printing.layoutPdf(
    name: jobName ?? 'Avahanaa sticker',
    format: pdfFormatFor(paper),
    dynamicLayout: false,
    onLayout: (format) => buildStickerSheetPdf(
      spec: spec,
      format: format,
      copies: copies,
      stickerPng: tile,
    ),
  );
}

/// Exports the sheet as a PDF file through the share sheet — the path for
/// "send it to the print shop on WhatsApp", which is how most of these
/// actually get printed.
Future<void> shareStickerSheetPdf({
  required StickerSpec spec,
  required SheetPaper paper,
  int copies = 1,
  required String filename,
}) async {
  final bytes = await buildStickerSheetPdf(
    spec: spec,
    format: pdfFormatFor(paper),
    copies: copies,
    stickerPng: await renderPrintTile(spec),
  );
  await Printing.sharePdf(bytes: bytes, filename: filename);
}
