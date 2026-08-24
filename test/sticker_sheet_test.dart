import 'package:avahanaa/utils/sticker_renderer.dart';
import 'package:avahanaa/utils/sticker_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet planner decides how big a printed sticker ends up, and a sticker
/// that prints too small stops reading through a windscreen. These pin the
/// geometry rather than the pixels.
void main() {
  group('SheetPlan', () {
    test('one copy on A4 fills the page inside the margin', () {
      final plan = SheetPlan.compute(pageSize: SheetPaper.a4.sizePt, copies: 1);

      expect(plan.slots, hasLength(1));
      expect(plan.columns, 1);
      expect(plan.rows, 1);

      final slot = plan.slots.single;
      expect(
        slot.width / slot.height,
        closeTo(kStickerAspectRatio, 0.001),
        reason: 'the slot must keep the sticker A-ratio',
      );
      expect(slot.left, greaterThanOrEqualTo(plan.margin - 0.01));
      expect(slot.right, lessThanOrEqualTo(SheetPaper.a4.widthPt + 0.01));
      expect(slot.bottom, lessThanOrEqualTo(SheetPaper.a4.heightPt + 0.01));
    });

    test('two copies on A4 stack, four tile 2x2', () {
      final two = SheetPlan.compute(pageSize: SheetPaper.a4.sizePt, copies: 2);
      expect(two.columns, 1);
      expect(two.rows, 2);

      final four = SheetPlan.compute(pageSize: SheetPaper.a4.sizePt, copies: 4);
      expect(four.columns, 2);
      expect(four.rows, 2);
    });

    test('slots never overlap', () {
      for (final copies in kSheetCopyOptions) {
        final plan = SheetPlan.compute(
          pageSize: SheetPaper.a4.sizePt,
          copies: copies,
        );
        for (var i = 0; i < plan.slots.length; i++) {
          for (var j = i + 1; j < plan.slots.length; j++) {
            expect(
              plan.slots[i].overlaps(plan.slots[j]),
              isFalse,
              reason: 'slots $i and $j overlap at $copies per sheet',
            );
          }
        }
      }
    });

    test('every slot stays inside the page', () {
      for (final paper in SheetPaper.values) {
        for (final copies in kSheetCopyOptions) {
          final plan = SheetPlan.compute(
            pageSize: paper.sizePt,
            copies: copies,
          );
          expect(plan.slots, hasLength(copies));
          for (final slot in plan.slots) {
            expect(slot.left, greaterThanOrEqualTo(-0.01));
            expect(slot.top, greaterThanOrEqualTo(-0.01));
            expect(slot.right, lessThanOrEqualTo(paper.widthPt + 0.01));
            expect(slot.bottom, lessThanOrEqualTo(paper.heightPt + 0.01));
          }
        }
      }
    });

    test('a landscape page re-flows instead of squashing', () {
      // What the print dialog reports after the user flips orientation.
      final plan = SheetPlan.compute(
        pageSize: Size(SheetPaper.a4.heightPt, SheetPaper.a4.widthPt),
        copies: 2,
      );
      expect(plan.columns, 2, reason: 'two portrait tiles sit side by side');
      expect(plan.rows, 1);
      for (final slot in plan.slots) {
        expect(slot.width / slot.height, closeTo(kStickerAspectRatio, 0.001));
      }
    });

    test('a single A4 sticker prints close to A5', () {
      final plan = SheetPlan.compute(pageSize: SheetPaper.a4.sizePt, copies: 1);
      final mm = plan.stickerSizeMm;
      // A5 is 148 x 210mm; the page margin takes a few millimetres off.
      expect(mm.width, greaterThan(130));
      expect(mm.height, greaterThan(185));
    });
  });

  _scanFloorContract();

  group('PDF export', () {
    const spec = StickerSpec(
      qrData: 'https://avahanaa.com/n/qr-abc123def456',
      plate: 'KA01AB1234',
      descriptor: 'White Maruti Swift',
    );

    test('produces a real PDF for every paper and copy count', () async {
      // Rasterise once and reuse, the same way `printStickerSheet` does. Doing
      // it per combination re-renders a 2250px tile twelve times and pushes the
      // test past the default timeout.
      final tile = await renderPrintTile(spec);
      expect(tile, isNotNull);

      for (final paper in SheetPaper.values) {
        for (final copies in kSheetCopyOptions) {
          final bytes = await buildStickerSheetPdf(
            spec: spec,
            format: pdfFormatFor(paper),
            copies: copies,
            stickerPng: tile,
          );
          expect(bytes.length, greaterThan(2000));
          // %PDF magic.
          expect(
            String.fromCharCodes(bytes.sublist(0, 4)),
            '%PDF',
            reason: '${paper.label} at $copies per sheet',
          );
        }
      }
    });
  });
}

/// The scan floor is the one number on this screen with a consequence: below
/// it the sticker prints a code nobody can read from outside the car.
void _scanFloorContract() {
  test('the scan floor flags exactly the sheets that print too small', () {
    bool tooSmall(SheetPaper paper, int copies) => SheetPlan.compute(
      pageSize: paper.sizePt,
      copies: copies,
    ).isBelowScanFloor;

    // Comfortable.
    expect(tooSmall(SheetPaper.a4, 1), isFalse);
    expect(tooSmall(SheetPaper.a4, 2), isFalse);
    expect(tooSmall(SheetPaper.a4, 4), isFalse);
    expect(tooSmall(SheetPaper.letter, 1), isFalse);
    expect(tooSmall(SheetPaper.a5, 1), isFalse);

    // Too small to scan through a windscreen.
    expect(tooSmall(SheetPaper.a5, 2), isTrue);
    expect(tooSmall(SheetPaper.a5, 4), isTrue);
    expect(tooSmall(SheetPaper.a6, 2), isTrue);
    expect(tooSmall(SheetPaper.a6, 4), isTrue);
  });
}
