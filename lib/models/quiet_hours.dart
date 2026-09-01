/// A window in which alerts arrive without the alarm.
///
/// The obvious way to build this would be to suppress notifications between
/// two times. That would be wrong, and on this product it would be dangerous:
/// a vehicle is towed at 3am, or somebody is breaking into it, and the one
/// mechanism the owner has for finding out has been switched off by a
/// preference they set months ago and forgot.
///
/// So quiet hours never silence anything. They reuse the delivery tier the
/// alert budget already introduced: inside the window a non-emergency alert
/// arrives on the quiet channel, with the phone's ordinary tone and no
/// escalating reminders. The alert is still delivered, still written, and
/// still answerable — the owner can still tell the person at their car that
/// they are coming.
///
/// Emergencies ignore the window entirely, exactly as they ignore the budget.
/// Somebody reporting a fire at 3am is the single case this feature must not
/// touch.
library;

/// Minutes since midnight, local time.
///
/// Stored as an int rather than a `TimeOfDay` so it round-trips through
/// Firestore and through the backend, which has no Flutter types and does the
/// same arithmetic.
typedef MinuteOfDay = int;

class QuietHours {
  const QuietHours({
    this.enabled = false,
    this.startMinute = 22 * 60,
    this.endMinute = 7 * 60,
  });

  final bool enabled;

  /// When the window opens, in minutes since local midnight.
  final MinuteOfDay startMinute;

  /// When it closes. May be *earlier* than [startMinute] — that is the normal
  /// case, since the useful window crosses midnight.
  final MinuteOfDay endMinute;

  static const QuietHours off = QuietHours();

  factory QuietHours.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return QuietHours(
      enabled: map['enabled'] == true,
      startMinute: _minute(map['startMinute'], 22 * 60),
      endMinute: _minute(map['endMinute'], 7 * 60),
    );
  }

  static MinuteOfDay _minute(Object? value, MinuteOfDay fallback) {
    final raw = value is num ? value.toInt() : null;
    if (raw == null) return fallback;
    // Wrapped rather than clamped: a stored 1440 means midnight, not 23:59.
    return raw % (24 * 60);
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'startMinute': startMinute,
    'endMinute': endMinute,
  };

  /// Whether [now] falls inside the window.
  ///
  /// Handles the wrap across midnight, which is the only case anybody actually
  /// configures: 22:00–07:00 is two ranges, not one.
  bool contains(DateTime now) {
    if (!enabled) return false;
    final minute = now.hour * 60 + now.minute;
    if (startMinute == endMinute) {
      // A zero-length window. Treated as off rather than as all day — the
      // latter would silence a whole day's alarms from a slip of a picker.
      return false;
    }
    if (startMinute < endMinute) {
      return minute >= startMinute && minute < endMinute;
    }
    return minute >= startMinute || minute < endMinute;
  }

  /// How long the window lasts, in minutes.
  ///
  /// Modular, because the useful window wraps: 22:00 to 07:00 is nine hours,
  /// not minus fifteen. A plain subtraction is the bug this replaced.
  int get lengthMinutes => (endMinute - startMinute) % (24 * 60);

  /// True when the window is a full 24 hours in practice.
  ///
  /// Surfaced in the UI, because "quiet all day, every day" is almost never
  /// what somebody meant to set and it quietly turns the product off. Note
  /// that a zero-length window is *not* this — [contains] reads that as off,
  /// which is the safe direction.
  bool get isEffectivelyAllDay => enabled && lengthMinutes >= 24 * 60 - 1;

  QuietHours copyWith({bool? enabled, MinuteOfDay? startMinute, MinuteOfDay? endMinute}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
      );

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      other.enabled == enabled &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(enabled, startMinute, endMinute);

  @override
  String toString() =>
      'QuietHours(${enabled ? "$startMinute-$endMinute" : "off"})';
}
