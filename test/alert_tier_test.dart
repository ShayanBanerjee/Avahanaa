/// Which way an unknown tier falls.
///
/// The whole safety argument for metering alerts rests on this one default: a
/// sender that says nothing must produce an alarm, never a quiet notice.
library;

import 'package:avahanaa/services/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlertTier.parse', () {
    test('an absent tier is full strength', () {
      // Every push from a backend older than this feature has no `tier` key.
      // Downgrading those would silently un-alarm the entire installed base.
      expect(AlertTier.parse(null), AlertTier.full);
      expect(AlertTier.parse(''), AlertTier.full);
    });

    test('an unrecognised tier is full strength', () {
      // A typo in a future backend, or a tier this build predates. Failing
      // towards the alarm is the only acceptable direction.
      expect(AlertTier.parse('silent'), AlertTier.full);
      expect(AlertTier.parse('QUIET'), AlertTier.full);
    });

    test('only the exact quiet token downgrades', () {
      expect(AlertTier.parse('quiet'), AlertTier.quiet);
      expect(AlertTier.parse('full'), AlertTier.full);
    });
  });

  group('payload round-trip', () {
    test('the tier survives the FCM data map', () {
      final payload = NotificationPayload.fromDataMap(const {
        'type': 'vehicle_alert',
        'notificationId': 'abc123',
        'title': 'Your vehicle is blocking a driveway',
        'body': 'Please move it',
        'reason': 'blocking_driveway',
        'tier': 'quiet',
      });
      expect(payload.tier, AlertTier.quiet);
      expect(payload.toDataMap()['tier'], 'quiet');
    });

    test('a payload with no tier key defaults to full', () {
      final payload = NotificationPayload.fromDataMap(const {
        'notificationId': 'abc123',
        'reason': 'emergency',
      });
      expect(payload.tier, AlertTier.full);
    });
  });
}
