/// The insights arithmetic — mostly a test that it refuses to lie.
///
/// Every case here is one where a naive implementation would present something
/// technically derivable and actually misleading: a mean dragged by one
/// overnight reply, a "busiest hour" computed from a single alert, a negative
/// response time from clock skew.
library;

import 'package:avahanaa/models/alert_insights.dart';
import 'package:avahanaa/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationModel alert({
  required DateTime sentAt,
  String reason = 'blocking_driveway',
  String vehicleId = 'veh1',
  DateTime? acknowledgedAt,
}) {
  return NotificationModel(
    id: '${sentAt.microsecondsSinceEpoch}-$reason',
    qrCodeId: 'qr1',
    userId: 'u1',
    vehicleId: vehicleId,
    reason: reason,
    message: 'x',
    sentAt: sentAt,
    acknowledgedAt: acknowledgedAt,
    acknowledgementEta: acknowledgedAt == null ? '' : 'omw_now',
  );
}

void main() {
  final now = DateTime(2026, 9, 15, 12);

  test('an empty history yields the empty insight', () {
    expect(AlertInsights.from(const []), AlertInsights.empty);
    expect(AlertInsights.empty.hasEnoughData, isFalse);
    expect(AlertInsights.empty.responseRate, 0);
  });

  test('counts this month separately from the whole window', () {
    final insights = AlertInsights.from([
      alert(sentAt: DateTime(2026, 9, 2)),
      alert(sentAt: DateTime(2026, 9, 14)),
      alert(sentAt: DateTime(2026, 8, 30)),
    ], now: now);

    expect(insights.total, 3);
    expect(insights.thisMonth, 2);
  });

  group('response time', () {
    test('is a median, so one overnight reply does not skew it', () {
      // The mean of 2, 3, 4 minutes and 11 hours is over two and a half hours,
      // which describes none of the four.
      final insights = AlertInsights.from([
        alert(
          sentAt: DateTime(2026, 9, 10, 9),
          acknowledgedAt: DateTime(2026, 9, 10, 9, 2),
        ),
        alert(
          sentAt: DateTime(2026, 9, 11, 9),
          acknowledgedAt: DateTime(2026, 9, 11, 9, 3),
        ),
        alert(
          sentAt: DateTime(2026, 9, 12, 9),
          acknowledgedAt: DateTime(2026, 9, 12, 9, 4),
        ),
        alert(
          sentAt: DateTime(2026, 9, 13, 22),
          acknowledgedAt: DateTime(2026, 9, 14, 9),
        ),
      ], now: now);

      expect(insights.medianResponse!.inMinutes, lessThan(10));
    });

    test('ignores a negative delta from clock skew', () {
      // The reply is stamped by the device, the alert by the server. A skewed
      // phone would otherwise produce "median response: -3 minutes".
      final insights = AlertInsights.from([
        alert(
          sentAt: DateTime(2026, 9, 10, 9),
          acknowledgedAt: DateTime(2026, 9, 10, 8, 57),
        ),
        alert(
          sentAt: DateTime(2026, 9, 11, 9),
          acknowledgedAt: DateTime(2026, 9, 11, 9, 5),
        ),
      ], now: now);

      expect(insights.medianResponse, const Duration(minutes: 5));
      // Still counted as answered — the owner did reply.
      expect(insights.acknowledged, 2);
    });

    test('is null when nothing was ever answered', () {
      final insights = AlertInsights.from([
        alert(sentAt: DateTime(2026, 9, 10)),
      ], now: now);
      expect(insights.medianResponse, isNull);
      expect(insights.responseRate, 0);
    });
  });

  group('busiest hour', () {
    test('needs more than one alert to claim a peak', () {
      // With one alert, "your busiest hour is 3pm" restates the only data
      // point back at the reader as though it were a finding.
      final insights = AlertInsights.from([
        alert(sentAt: DateTime(2026, 9, 10, 15)),
      ], now: now);
      expect(insights.busiestHour, isNull);
    });

    test('reports a real peak', () {
      final insights = AlertInsights.from([
        alert(sentAt: DateTime(2026, 9, 10, 19)),
        alert(sentAt: DateTime(2026, 9, 11, 19)),
        alert(sentAt: DateTime(2026, 9, 12, 8)),
      ], now: now);
      expect(insights.busiestHour, 19);
    });
  });

  group('breakdowns', () {
    test('rank by count, descending', () {
      final insights = AlertInsights.from([
        alert(sentAt: DateTime(2026, 9, 1), reason: 'illegal_parking'),
        alert(sentAt: DateTime(2026, 9, 2), reason: 'blocking_driveway'),
        alert(sentAt: DateTime(2026, 9, 3), reason: 'blocking_driveway'),
      ], now: now);

      expect(insights.byReason.first.key, 'blocking_driveway');
      expect(insights.byReason.first.count, 2);
    });

    test('ties break on the key, so the order does not shuffle', () {
      final insights = AlertInsights.from([
        alert(sentAt: DateTime(2026, 9, 1), reason: 'zebra'),
        alert(sentAt: DateTime(2026, 9, 2), reason: 'alpha'),
      ], now: now);
      expect(insights.byReason.map((e) => e.key), ['alpha', 'zebra']);
    });

    test('a vehicle-less alert does not create an empty row', () {
      // Self-test alerts carry no vehicleId.
      final insights = AlertInsights.from([
        alert(sentAt: DateTime(2026, 9, 1), vehicleId: ''),
        alert(sentAt: DateTime(2026, 9, 2), vehicleId: 'veh1'),
      ], now: now);
      expect(insights.byVehicle.length, 1);
      expect(insights.byVehicle.single.key, 'veh1');
    });
  });

  test('emergencies are counted on their own', () {
    final insights = AlertInsights.from([
      alert(sentAt: DateTime(2026, 9, 1), reason: 'emergency'),
      alert(sentAt: DateTime(2026, 9, 2), reason: 'other'),
    ], now: now);
    expect(insights.emergencies, 1);
  });
}
