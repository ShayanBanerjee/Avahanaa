import 'package:flutter/material.dart';

import 'notification_payload.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final List<String> _pendingNotificationIds = <String>[];
  static Route<void> Function(String notificationId)? _routeFactory;
  static bool _isNavigating = false;

  static void configureRouteFactory(
    Route<void> Function(String notificationId) routeFactory,
  ) {
    _routeFactory = routeFactory;
  }

  static void openFromRawPayload(String? payload) {
    final tapPayload = NotificationPayload.parseTapPayload(payload);
    if (tapPayload == null) {
      return;
    }
    openByNotificationId(tapPayload.notificationId);
  }

  static void openByNotificationId(String notificationId) {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _enqueuePending(trimmed);
      return;
    }

    _pushNotificationsScreen(navigator, trimmed);
  }

  static void drainPending() {
    final navigator = navigatorKey.currentState;
    if (navigator == null || _pendingNotificationIds.isEmpty) {
      return;
    }

    final nextId = _pendingNotificationIds.removeAt(0);
    _pushNotificationsScreen(navigator, nextId);
  }

  static void _pushNotificationsScreen(
    NavigatorState navigator,
    String notificationId,
  ) {
    final routeFactory = _routeFactory;
    if (routeFactory == null) {
      _enqueuePending(notificationId);
      return;
    }

    if (_isNavigating) {
      _enqueuePending(notificationId);
      return;
    }

    _isNavigating = true;
    navigator.push(routeFactory(notificationId)).whenComplete(() {
      _isNavigating = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => drainPending());
    });
  }

  static void _enqueuePending(String notificationId) {
    if (_pendingNotificationIds.contains(notificationId)) {
      return;
    }
    _pendingNotificationIds.add(notificationId);
  }
}
