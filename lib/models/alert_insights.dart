/// What the alerts add up to.
///
/// Computed entirely from the notification list the app already streams — no
/// extra Firestore reads, no aggregation queries, no new indexes. That is the
/// whole reason this feature is cheap enough to be worth having.
///
/// The honest limitation, and the UI says it out loud: the streamed list is
/// capped at 50, so this describes the last 50 alerts rather than all history.
/// Presenting it as "all time" would be a number that silently stops growing.
library;

import 'notification_model.dart';

/// One row of the "where your alerts come from" breakdown.
class InsightCount {
  const InsightCount(this.key, this.count);
  final String key;
  final int count;
}

class AlertInsights {
  const AlertInsights({
    required this.total,
    required this.thisMonth,
    required this.acknowledged,
    required this.medianResponse,
    required this.byReason,
    required this.byVehicle,
    required this.busiestHour,
    required this.emergencies,
  });

  /// How many alerts this was computed from.
  final int total;

  final int thisMonth;

  /// How many the owner answered — with a reply, not merely opened.
  final int acknowledged;

  /// Typical time from alert to reply.
  ///
  /// Median rather than mean, deliberately. One alert answered eleven hours
  /// later because the owner was asleep would drag a mean into uselessness,
  /// and the number people want is "how fast do I usually answer".
  final Duration? medianResponse;

  final List<InsightCount> byReason;
  final List<InsightCount> byVehicle;

  /// Hour of day, 0–23, that sees the most alerts. Null when there is no
  /// meaningful peak.
  final int? busiestHour;

  final int emergencies;

  static const AlertInsights empty = AlertInsights(
    total: 0,
    thisMonth: 0,
    acknowledged: 0,
    medianResponse: null,
    byReason: [],
    byVehicle: [],
    busiestHour: null,
    emergencies: 0,
  );

  bool get hasEnoughData => total > 0;

  /// Share of alerts the owner answered, 0–1.
  double get responseRate => total == 0 ? 0 : acknowledged / total;

  factory AlertInsights.from(
    List<NotificationModel> alerts, {
    DateTime? now,
  }) {
    if (alerts.isEmpty) return AlertInsights.empty;

    final clock = now ?? DateTime.now();
    final monthStart = DateTime(clock.year, clock.month);

    var thisMonth = 0;
    var acknowledged = 0;
    var emergencies = 0;
    final reasons = <String, int>{};
    final vehicles = <String, int>{};
    final hours = List<int>.filled(24, 0);
    final responses = <Duration>[];

    for (final alert in alerts) {
      if (!alert.sentAt.isBefore(monthStart)) thisMonth++;
      if (alert.reason == 'emergency') emergencies++;

      reasons[alert.reason] = (reasons[alert.reason] ?? 0) + 1;
      if (alert.vehicleId.isNotEmpty) {
        vehicles[alert.vehicleId] = (vehicles[alert.vehicleId] ?? 0) + 1;
      }
      hours[alert.sentAt.hour]++;

      final repliedAt = alert.acknowledgedAt;
      if (repliedAt != null) {
        acknowledged++;
        final delta = repliedAt.difference(alert.sentAt);
        // A negative delta means clock skew between the device that wrote the
        // reply and the server that stamped the alert. Counting it would
        // produce a "median response: -3 minutes", which is worse than
        // dropping it.
        if (!delta.isNegative) responses.add(delta);
      }
    }

    return AlertInsights(
      total: alerts.length,
      thisMonth: thisMonth,
      acknowledged: acknowledged,
      medianResponse: _median(responses),
      byReason: _ranked(reasons),
      byVehicle: _ranked(vehicles),
      busiestHour: _peak(hours),
      emergencies: emergencies,
    );
  }

  static Duration? _median(List<Duration> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return Duration(
      microseconds:
          (sorted[middle - 1].inMicroseconds + sorted[middle].inMicroseconds) ~/
          2,
    );
  }

  static List<InsightCount> _ranked(Map<String, int> counts) {
    final entries = counts.entries.toList()
      // Count descending, then key, so the order is stable rather than
      // shuffling between rebuilds when two rows tie.
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return [for (final e in entries) InsightCount(e.key, e.value)];
  }

  /// The busiest hour, or null when nothing stands out.
  ///
  /// Requires the peak to hold at least two alerts. With one alert in a bucket
  /// "your busiest hour is 3pm" is not an insight, it is a restatement of the
  /// only data point.
  static int? _peak(List<int> hours) {
    var best = 0;
    for (var i = 1; i < hours.length; i++) {
      if (hours[i] > hours[best]) best = i;
    }
    return hours[best] >= 2 ? best : null;
  }
}
