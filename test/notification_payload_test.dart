import 'package:avahanaa/services/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload.fromDataMap', () {
    test('parses required contract fields', () {
      final payload = NotificationPayload.fromDataMap({
        'type': 'vehicle_alert',
        'notificationId': 'notif-123',
        'title': 'Emergency',
        'body': 'Move the vehicle now',
        'reason': 'emergency',
        'sentAt': '2026-03-13T12:00:00Z',
      });

      expect(payload.type, 'vehicle_alert');
      expect(payload.notificationId, 'notif-123');
      expect(payload.title, 'Emergency');
      expect(payload.body, 'Move the vehicle now');
      expect(payload.reason, 'emergency');
      expect(payload.sentAtUtc.toIso8601String(), '2026-03-13T12:00:00.000Z');
    });

    test('falls back for legacy payload values', () {
      final payload = NotificationPayload.fromDataMap(
        {'reason': 'other'},
        fallbackId: 'message-id-9',
        fallbackTitle: 'Vehicle alert',
        fallbackBody: 'Fallback body',
      );

      expect(payload.notificationId, 'message-id-9');
      expect(payload.title, 'Vehicle alert');
      expect(payload.body, 'Fallback body');
      expect(payload.type, NotificationPayload.vehicleAlertType);
    });

    test('supports epoch seconds sentAt', () {
      final payload = NotificationPayload.fromDataMap({
        'notificationId': 'notif-epoch',
        'sentAt': '1710331200',
      });

      expect(payload.sentAtUtc.year, 2024);
      expect(payload.sentAtUtc.isUtc, true);
    });
  });

  group('NotificationPayload.parseTapPayload', () {
    test('parses structured local payload', () {
      const rawPayload =
          '{"notificationId":"abc-1","isReminder":true,"reminderStep":2}';
      final parsed = NotificationPayload.parseTapPayload(rawPayload);

      expect(parsed, isNotNull);
      expect(parsed!.notificationId, 'abc-1');
      expect(parsed.isReminder, true);
      expect(parsed.reminderStep, 2);
    });

    test('parses plain legacy id payload', () {
      final parsed = NotificationPayload.parseTapPayload('legacy-id');

      expect(parsed, isNotNull);
      expect(parsed!.notificationId, 'legacy-id');
      expect(parsed.isReminder, false);
    });
  });

  group('NotificationReminderIds', () {
    test('returns deterministic unique IDs per notification', () {
      final all = NotificationReminderIds.allFor('notif-A');

      expect(all.length, 3);
      expect(all.toSet().length, 3);
      expect(all.first, NotificationReminderIds.primaryId('notif-A'));
      expect(all[1], NotificationReminderIds.reminderOneId('notif-A'));
      expect(all[2], NotificationReminderIds.reminderTwoId('notif-A'));
    });

    test('IDs differ between notification IDs', () {
      final a = NotificationReminderIds.allFor('notif-A');
      final b = NotificationReminderIds.allFor('notif-B');

      expect(a[0], isNot(equals(b[0])));
    });
  });
}
