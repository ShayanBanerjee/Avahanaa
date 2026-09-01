/// The quiet-hours window, whose only job is to be right about midnight.
///
/// Every interesting case here crosses it, because the window anybody actually
/// configures — 22:00 to 07:00 — is two ranges rather than one. Getting that
/// backwards inverts the feature: silent all day, loud all night.
library;

import 'package:avahanaa/models/quiet_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 9, 1, hour, minute);

  group('a window that crosses midnight', () {
    const night = QuietHours(
      enabled: true,
      startMinute: 22 * 60,
      endMinute: 7 * 60,
    );

    test('covers the late evening', () {
      expect(night.contains(at(22)), isTrue);
      expect(night.contains(at(23, 59)), isTrue);
    });

    test('covers the small hours', () {
      expect(night.contains(at(0)), isTrue);
      expect(night.contains(at(3, 30)), isTrue);
      expect(night.contains(at(6, 59)), isTrue);
    });

    test('ends exactly on the end minute', () {
      // Half-open, so a 07:00 window boundary means alarms are back at 07:00
      // rather than 07:01.
      expect(night.contains(at(7)), isFalse);
    });

    test('leaves the day alone', () {
      expect(night.contains(at(9)), isFalse);
      expect(night.contains(at(14, 30)), isFalse);
      expect(night.contains(at(21, 59)), isFalse);
    });
  });

  group('a window inside one day', () {
    const meeting = QuietHours(
      enabled: true,
      startMinute: 9 * 60,
      endMinute: 17 * 60,
    );

    test('contains only its own range', () {
      expect(meeting.contains(at(8, 59)), isFalse);
      expect(meeting.contains(at(9)), isTrue);
      expect(meeting.contains(at(16, 59)), isTrue);
      expect(meeting.contains(at(17)), isFalse);
      expect(meeting.contains(at(2)), isFalse);
    });
  });

  group('the off switch', () {
    test('a disabled window contains nothing, whatever the times say', () {
      const off = QuietHours(startMinute: 0, endMinute: 23 * 60 + 59);
      for (var hour = 0; hour < 24; hour++) {
        expect(off.contains(at(hour)), isFalse);
      }
    });

    test('a zero-length window reads as off, never as all day', () {
      // The dangerous misreading. A slip of the picker that set start == end
      // must not silence the alarm for twenty-four hours.
      const zero = QuietHours(
        enabled: true,
        startMinute: 8 * 60,
        endMinute: 8 * 60,
      );
      expect(zero.contains(at(8)), isFalse);
      expect(zero.contains(at(20)), isFalse);
    });
  });

  group('the all-day guard', () {
    test('flags a window that would never let an alarm through', () {
      const allDay = QuietHours(
        enabled: true,
        startMinute: 0,
        endMinute: 24 * 60 - 1,
      );
      expect(allDay.isEffectivelyAllDay, isTrue);
    });

    test('does not flag an ordinary night', () {
      const night = QuietHours(
        enabled: true,
        startMinute: 22 * 60,
        endMinute: 7 * 60,
      );
      expect(night.isEffectivelyAllDay, isFalse);
    });

    test('a disabled window is never flagged', () {
      const off = QuietHours(startMinute: 0, endMinute: 24 * 60 - 1);
      expect(off.isEffectivelyAllDay, isFalse);
    });
  });

  group('storage', () {
    test('round-trips through a map', () {
      const original = QuietHours(
        enabled: true,
        startMinute: 23 * 60 + 15,
        endMinute: 6 * 60 + 45,
      );
      expect(QuietHours.fromMap(original.toMap()), original);
    });

    test('a missing or malformed map is off with sane defaults', () {
      expect(QuietHours.fromMap(null).enabled, isFalse);
      expect(QuietHours.fromMap(const {}).enabled, isFalse);
      expect(QuietHours.fromMap(const {'enabled': 'yes'}).enabled, isFalse);
    });

    test('a minute past midnight wraps rather than clamping', () {
      // 1440 is midnight, not 23:59. Clamping would move the boundary by a
      // minute every time it round-tripped.
      final wrapped = QuietHours.fromMap(const {
        'enabled': true,
        'startMinute': 24 * 60,
        'endMinute': 60,
      });
      expect(wrapped.startMinute, 0);
    });
  });
}
