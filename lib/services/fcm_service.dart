import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'congestion_free_channel',
    'Avahanaa Alerts',
    description: 'Important notifications for vehicle alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  static const String _defaultTitle = 'Vehicle alert';
  static const String _defaultBody =
      'Someone is trying to notify you about your vehicle.';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isLocalNotificationsInitialized = false;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final canNotify =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!canNotify) {
      debugPrint('User declined notification permission');
      return;
    }

    log('User granted notification permission');

    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveFCMToken);

    // Initialize local notifications
    await initializeLocalNotifications();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> initializeLocalNotifications() async {
    if (kIsWeb || _isLocalNotificationsInitialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Keeps foreground notification behavior consistent on Apple platforms.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    _isLocalNotificationsInitialized = true;
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved: $token');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');

    FCMService.showNotificationForMessage(message).catchError((e, stackTrace) {
      log(
        'Error showing local notification: $e',
        error: e,
        stackTrace: stackTrace,
      );
    });
  }

  // Handle notification tap (when app is in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');

    // Navigate to notifications screen
    // You can implement navigation logic here
    // For example: navigatorKey.currentState?.pushNamed('/notifications');
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  // Refresh and persist current FCM token
  Future<void> refreshFcmToken() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }
  }

  // Delete FCM token
  Future<void> deleteFCMToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        await _fcm.deleteToken();
      } catch (e) {
        debugPrint('Error deleting FCM token: $e');
      }
    }
  }

  // Subscribe to topic (optional for future features)
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  static Future<void> showNotificationForMessage(RemoteMessage message) async {
    await initializeLocalNotifications();

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        _defaultTitle;
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        _defaultBody;

    final now = DateTime.now();
    final rawId =
        message.messageId?.hashCode ??
        message.sentTime?.millisecondsSinceEpoch ??
        now.millisecondsSinceEpoch;
    final notificationId = _normalizeNotificationId(rawId);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(body),
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload:
          message.data['notificationId']?.toString() ?? message.messageId ?? '',
    );
  }

  static int _normalizeNotificationId(int rawId) {
    final safeId = rawId.abs() % 2147480000;
    if (safeId == 0 || safeId == 1) return 2;
    return safeId;
  }
}
