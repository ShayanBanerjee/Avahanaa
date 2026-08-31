/// Will this phone actually wake its owner up?
///
/// Everything else in this app is downstream of that question, and until now
/// nothing answered it. The alert path can be perfect end to end and still
/// deliver nothing, because the failure lives on the device: a notification
/// permission that was never granted, a channel the owner muted six months ago
/// after one noisy week, or — most often in this market — a manufacturer's
/// battery optimiser that kills the process and reports nothing to anybody.
///
/// Xiaomi, Oppo, Vivo, Realme and Samsung all ship one. There is no API that
/// tells you it is on, no callback when it fires, and no error anywhere. The
/// owner finds out when somebody keys their car.
///
/// So this checks what *can* be checked, says plainly what it cannot, and
/// points at the self-test for the rest. The honest split matters: reporting
/// "all good" from four green ticks when the fifth thing is unobservable would
/// be worse than saying nothing.
library;

import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// One thing that has to be true for an alert to land.
enum ReadinessCheck {
  /// The OS-level notification permission (Android 13+, and iOS always).
  notificationPermission,

  /// The owner's own switch, in this app's settings.
  appPreference,

  /// A push token exists and has been written to the user document.
  pushToken,

  /// Permission to take over the lock screen.
  ///
  /// Advisory only: a refusal here downgrades the alert to a heads-up on a
  /// max-importance channel, which is still loud. It is listed because the
  /// difference is visible and worth explaining, never because it is required.
  fullScreenIntent,
}

class ReadinessReport {
  const ReadinessReport({
    required this.failures,
    required this.advisories,
  });

  /// Checks that will stop an alert reaching the owner.
  final Set<ReadinessCheck> failures;

  /// Checks that only make an alert quieter.
  final Set<ReadinessCheck> advisories;

  static const ReadinessReport healthy = ReadinessReport(
    failures: {},
    advisories: {},
  );

  bool get isHealthy => failures.isEmpty;
  bool get hasAnything => failures.isNotEmpty || advisories.isNotEmpty;

  /// The one check to lead with.
  ///
  /// A card that lists four problems gets read as "this app is broken" and
  /// dismissed. One problem with one button gets fixed. Ordered by how
  /// completely each failure silences the alert.
  ReadinessCheck? get headline {
    for (final check in const [
      ReadinessCheck.notificationPermission,
      ReadinessCheck.appPreference,
      ReadinessCheck.pushToken,
    ]) {
      if (failures.contains(check)) return check;
    }
    return advisories.isEmpty ? null : advisories.first;
  }
}

abstract final class AlertReadiness {
  /// Inspects the device.
  ///
  /// Never throws. A check that cannot be performed — an old Android with no
  /// runtime notification permission, a plugin call that fails — counts as
  /// passing. This is a diagnostic, and a diagnostic that invents faults is
  /// worse than one that misses them: it trains people to ignore it.
  static Future<ReadinessReport> inspect({
    required bool appPreferenceEnabled,
    required bool hasStoredToken,
  }) async {
    if (kIsWeb) return ReadinessReport.healthy;

    final failures = <ReadinessCheck>{};
    final advisories = <ReadinessCheck>{};

    if (!appPreferenceEnabled) failures.add(ReadinessCheck.appPreference);
    if (!hasStoredToken) failures.add(ReadinessCheck.pushToken);

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        failures.add(ReadinessCheck.notificationPermission);
      }
    } catch (e) {
      log('Could not read notification settings: $e');
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final android = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        // Explicitly `== false`. Null means the platform did not answer, which
        // on older Android simply means there is nothing to grant.
        if (await android?.areNotificationsEnabled() == false) {
          failures.add(ReadinessCheck.notificationPermission);
        }
        if (await android?.canScheduleExactNotifications() == false) {
          // Only the escalating reminders depend on this; the first alert
          // still lands. Advisory, not a failure.
          advisories.add(ReadinessCheck.fullScreenIntent);
        }
      } catch (e) {
        log('Could not read Android notification state: $e');
      }
    }

    return ReadinessReport(failures: failures, advisories: advisories);
  }

  /// Asks for whatever [check] needs, and reports whether it was granted.
  ///
  /// Returns false for checks that cannot be fixed from here — the app's own
  /// preference is a switch in this app, and a missing push token fixes itself
  /// once notifications are granted.
  static Future<bool> request(ReadinessCheck check) async {
    if (kIsWeb) return false;

    try {
      switch (check) {
        case ReadinessCheck.notificationPermission:
          if (defaultTargetPlatform == TargetPlatform.android) {
            final android = FlutterLocalNotificationsPlugin()
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
            return await android?.requestNotificationsPermission() ?? false;
          }
          final settings = await FirebaseMessaging.instance.requestPermission();
          return settings.authorizationStatus == AuthorizationStatus.authorized;

        case ReadinessCheck.fullScreenIntent:
          final android = FlutterLocalNotificationsPlugin()
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          return await android?.requestFullScreenIntentPermission() ?? false;

        case ReadinessCheck.appPreference:
        case ReadinessCheck.pushToken:
          return false;
      }
    } catch (e) {
      log('Permission request failed for $check: $e');
      return false;
    }
  }
}
