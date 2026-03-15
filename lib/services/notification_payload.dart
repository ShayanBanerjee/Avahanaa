import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPayload {
  static const String vehicleAlertType = 'vehicle_alert';
  static const String defaultTitle = 'Vehicle alert';
  static const String defaultBody =
      'Someone is trying to notify you about your vehicle.';
  static const String defaultReason = 'other';

  final String type;
  final String notificationId;
  final String title;
  final String body;
  final String reason;
  final DateTime sentAtUtc;

  const NotificationPayload({
    required this.type,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.reason,
    required this.sentAtUtc,
  });

  bool get isVehicleAlert => type == vehicleAlertType;

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return NotificationPayload.fromDataMap(
      message.data,
      fallbackId: message.messageId,
      fallbackTitle: message.notification?.title,
      fallbackBody: message.notification?.body,
      fallbackSentAtUtc: message.sentTime?.toUtc(),
    );
  }

  factory NotificationPayload.fromDataMap(
    Map<String, dynamic> rawData, {
    String? fallbackId,
    String? fallbackTitle,
    String? fallbackBody,
    DateTime? fallbackSentAtUtc,
  }) {
    final data = <String, dynamic>{};
    for (final entry in rawData.entries) {
      data[entry.key] = entry.value?.toString();
    }

    final nowUtc = DateTime.now().toUtc();
    final sentAtUtc =
        _parseSentAtUtc(data['sentAt']) ?? fallbackSentAtUtc?.toUtc() ?? nowUtc;
    final safeFallbackId = fallbackId?.trim().isNotEmpty == true
        ? fallbackId!.trim()
        : sentAtUtc.millisecondsSinceEpoch.toString();

    final notificationId =
        _firstNonEmpty([
          data['notificationId'],
          data['notification_id'],
          data['id'],
        ]) ??
        safeFallbackId;

    final type = _firstNonEmpty([data['type']]) ?? vehicleAlertType;
    final title =
        _firstNonEmpty([data['title'], fallbackTitle]) ?? defaultTitle;
    final body = _firstNonEmpty([data['body'], fallbackBody]) ?? defaultBody;
    final reason = _firstNonEmpty([data['reason']]) ?? defaultReason;

    return NotificationPayload(
      type: type,
      notificationId: notificationId,
      title: title,
      body: body,
      reason: reason,
      sentAtUtc: sentAtUtc,
    );
  }

  Map<String, dynamic> toDataMap() {
    return {
      'type': type,
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'reason': reason,
      'sentAt': sentAtUtc.toIso8601String(),
    };
  }

  String toLocalPayloadString({
    required bool isReminder,
    required int reminderStep,
  }) {
    return jsonEncode({
      'notificationId': notificationId,
      'type': type,
      'reason': reason,
      'sentAt': sentAtUtc.toIso8601String(),
      'isReminder': isReminder,
      'reminderStep': reminderStep,
    });
  }

  static NotificationTapPayload? parseTapPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    final trimmed = payload.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final notificationId = (decoded['notificationId'] ?? '').toString();
        if (notificationId.trim().isEmpty) {
          return null;
        }
        final isReminder = decoded['isReminder'] == true;
        final reminderStep =
            int.tryParse((decoded['reminderStep'] ?? 0).toString()) ?? 0;
        return NotificationTapPayload(
          notificationId: notificationId.trim(),
          isReminder: isReminder,
          reminderStep: reminderStep,
        );
      }
    } catch (_) {
      // Backward compatibility: legacy payload may be plain notificationId.
    }

    return NotificationTapPayload(
      notificationId: trimmed,
      isReminder: false,
      reminderStep: 0,
    );
  }

  static DateTime? _parseSentAtUtc(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    final asInt = int.tryParse(value);
    if (asInt != null) {
      final isSecondsPrecision = asInt.abs() < 1000000000000;
      final millis = isSecondsPrecision ? asInt * 1000 : asInt;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) {
      return parsedIso.toUtc();
    }
    return null;
  }

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class NotificationTapPayload {
  final String notificationId;
  final bool isReminder;
  final int reminderStep;

  const NotificationTapPayload({
    required this.notificationId,
    required this.isReminder,
    required this.reminderStep,
  });
}

class NotificationReminderIds {
  static const int _maxSafeId = 2147480000;
  static const int _reservedIdFloor = 2;
  static const int _reminderOneOffset = 7001;
  static const int _reminderTwoOffset = 14021;

  const NotificationReminderIds._();

  static int primaryId(String notificationId) {
    return _normalize(notificationId.hashCode);
  }

  static int reminderOneId(String notificationId) {
    return _normalize(primaryId(notificationId) + _reminderOneOffset);
  }

  static int reminderTwoId(String notificationId) {
    return _normalize(primaryId(notificationId) + _reminderTwoOffset);
  }

  static List<int> allFor(String notificationId) {
    return [
      primaryId(notificationId),
      reminderOneId(notificationId),
      reminderTwoId(notificationId),
    ];
  }

  static int _normalize(int rawId) {
    final safeId = rawId.abs() % _maxSafeId;
    if (safeId <= _reservedIdFloor) {
      return _reservedIdFloor + 1;
    }
    return safeId;
  }
}
