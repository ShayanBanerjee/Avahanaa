import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_navigation_service.dart';
import 'notification_payload.dart';

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  final _ = response;
  // Handled via getNotificationAppLaunchDetails() in the main isolate.
}

class FCMService {
  static const Duration _reminderDelayOne = Duration(minutes: 3);
  static const Duration _reminderDelayTwo = Duration(minutes: 15);
  static const Duration _seenRetentionWindow = Duration(days: 7);
  static const int _maxSeenEntries = 500;
  static const String _stateFileName =
      'avahanaa_notification_orchestrator_state_v1.json';

  static final AndroidNotificationChannel _criticalChannel =
      AndroidNotificationChannel(
        'avahanaa_critical_alerts_v2',
        'Avahanaa Critical Alerts',
        description: 'Critical vehicle alerts that require quick action',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static final AndroidNotificationChannel _legacyChannel =
      AndroidNotificationChannel(
        'congestion_free_channel',
        'Avahanaa Alerts',
        description: 'Important notifications for vehicle alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static final Int64List _strongVibrationPattern = Int64List.fromList([
    0,
    900,
    250,
    900,
  ]);

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isLocalNotificationsInitialized = false;
  static bool _isTimezoneInitialized = false;
  static bool _stateLoaded = false;
  static File? _stateFile;
  static final Map<String, int> _seenAtUtcMillis = <String, int>{};
  static final Map<String, List<int>> _scheduledReminderIds =
      <String, List<int>>{};

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final canNotify =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (canNotify) {
      log('User granted notification permission');
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }
      _fcm.onTokenRefresh.listen(_saveFCMToken);
    } else {
      debugPrint('User declined notification permission');
    }

    await initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    await _handleLocalNotificationLaunchDetails();
    await _syncReminderStateFromFirestore();
  }

  static Future<void> initializeLocalNotifications() async {
    if (kIsWeb || _isLocalNotificationsInitialized) {
      return;
    }

    _initializeTimeZones();

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
      onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_legacyChannel);
    await androidPlugin?.createNotificationChannel(_criticalChannel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    _isLocalNotificationsInitialized = true;
  }

  static void _initializeTimeZones() {
    if (_isTimezoneInitialized) {
      return;
    }
    tzdata.initializeTimeZones();
    _isTimezoneInitialized = true;
  }

  static void _handleLocalNotificationResponse(NotificationResponse response) {
    final tapPayload = NotificationPayload.parseTapPayload(response.payload);
    if (tapPayload == null) {
      return;
    }

    unawaited(
      cancelNotificationLifecycleById(
        tapPayload.notificationId,
        includePrimaryNotification: false,
      ),
    );
    NotificationNavigationService.openByNotificationId(
      tapPayload.notificationId,
    );
  }

  Future<void> _handleLocalNotificationLaunchDetails() async {
    final details = await _localNotifications.getNotificationAppLaunchDetails();
    if (!(details?.didNotificationLaunchApp ?? false)) {
      return;
    }

    final tapPayload = NotificationPayload.parseTapPayload(
      details?.notificationResponse?.payload,
    );
    if (tapPayload == null) {
      return;
    }

    await cancelNotificationLifecycleById(
      tapPayload.notificationId,
      includePrimaryNotification: false,
    );
    NotificationNavigationService.openByNotificationId(
      tapPayload.notificationId,
    );
  }

  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

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

  void _handleNotificationTap(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(message);
    if (payload.notificationId.isEmpty) {
      return;
    }

    unawaited(
      cancelNotificationLifecycleById(
        payload.notificationId,
        includePrimaryNotification: false,
      ),
    );
    NotificationNavigationService.openByNotificationId(payload.notificationId);
  }

  Future<String?> getFCMToken() async {
    return _fcm.getToken();
  }

  Future<void> refreshFcmToken() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }
  }

  Future<void> deleteFCMToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint('Error deleting token from Firestore: $e');
      }
    }
    await _fcm.deleteToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  static Future<void> showNotificationForMessage(RemoteMessage message) async {
    if (kIsWeb) {
      return;
    }

    await initializeLocalNotifications();
    await _loadState();

    final payload = NotificationPayload.fromRemoteMessage(message);
    if (_isDuplicateNotification(payload.notificationId)) {
      debugPrint('Skipping duplicate notification ${payload.notificationId}');
      return;
    }

    _markNotificationAsSeen(payload.notificationId, payload.sentAtUtc);
    await _showImmediateNotification(payload);
    await _scheduleReminders(payload);
    await _persistState();
  }

  static Future<void> cancelNotificationLifecycleById(
    String notificationId, {
    bool includePrimaryNotification = true,
  }) async {
    if (kIsWeb || notificationId.trim().isEmpty) {
      return;
    }

    await initializeLocalNotifications();
    await _loadState();
    await _cancelReminderNotifications(
      notificationId.trim(),
      includePrimaryNotification: includePrimaryNotification,
    );
    await _persistState();
  }

  static Future<void> cancelNotificationLifecycleByIds(
    Iterable<String> notificationIds, {
    bool includePrimaryNotification = true,
  }) async {
    if (kIsWeb) {
      return;
    }

    await initializeLocalNotifications();
    await _loadState();
    for (final rawId in notificationIds) {
      final notificationId = rawId.trim();
      if (notificationId.isEmpty) {
        continue;
      }
      await _cancelReminderNotifications(
        notificationId,
        includePrimaryNotification: includePrimaryNotification,
      );
    }
    await _persistState();
  }

  static Future<void> _showImmediateNotification(
    NotificationPayload payload,
  ) async {
    await _localNotifications.show(
      NotificationReminderIds.primaryId(payload.notificationId),
      payload.title,
      payload.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _criticalChannel.id,
          _criticalChannel.name,
          channelDescription: _criticalChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _strongVibrationPattern,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(payload.body),
          icon: '@mipmap/launcher_icon',
          ticker: payload.title,
          color: const Color(0xFFDC2626),
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload.toLocalPayloadString(isReminder: false, reminderStep: 0),
    );
  }

  static Future<void> _scheduleReminders(NotificationPayload payload) async {
    await _cancelReminderNotifications(
      payload.notificationId,
      includePrimaryNotification: false,
    );

    final nowUtc = DateTime.now().toUtc();
    final reminders = [
      (step: 1, delay: _reminderDelayOne),
      (step: 2, delay: _reminderDelayTwo),
    ];
    final scheduledIds = <int>[];

    for (final reminder in reminders) {
      final targetUtc = payload.sentAtUtc.add(reminder.delay);
      if (!targetUtc.isAfter(nowUtc)) {
        continue;
      }

      final reminderId = reminder.step == 1
          ? NotificationReminderIds.reminderOneId(payload.notificationId)
          : NotificationReminderIds.reminderTwoId(payload.notificationId);
      final reminderTitle = 'Reminder: ${payload.title}';

      await _localNotifications.zonedSchedule(
        reminderId,
        reminderTitle,
        payload.body,
        tz.TZDateTime.from(targetUtc, tz.UTC),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _criticalChannel.id,
            _criticalChannel.name,
            channelDescription: _criticalChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _strongVibrationPattern,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(payload.body),
            icon: '@mipmap/launcher_icon',
            ticker: reminderTitle,
            color: const Color(0xFFB91C1C),
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload.toLocalPayloadString(
          isReminder: true,
          reminderStep: reminder.step,
        ),
      );

      scheduledIds.add(reminderId);
    }

    if (scheduledIds.isEmpty) {
      _scheduledReminderIds.remove(payload.notificationId);
    } else {
      _scheduledReminderIds[payload.notificationId] = scheduledIds;
    }
  }

  static Future<void> _cancelReminderNotifications(
    String notificationId, {
    required bool includePrimaryNotification,
  }) async {
    final knownReminderIds = _scheduledReminderIds.remove(notificationId);
    final fallbackReminderIds = <int>[
      NotificationReminderIds.reminderOneId(notificationId),
      NotificationReminderIds.reminderTwoId(notificationId),
    ];
    final reminderIds = knownReminderIds ?? fallbackReminderIds;

    for (final reminderId in reminderIds) {
      await _localNotifications.cancel(reminderId);
    }

    if (includePrimaryNotification) {
      await _localNotifications.cancel(
        NotificationReminderIds.primaryId(notificationId),
      );
    }
  }

  static bool _isDuplicateNotification(String notificationId) {
    if (notificationId.trim().isEmpty) {
      return false;
    }
    _pruneSeenEntries();
    return _seenAtUtcMillis.containsKey(notificationId);
  }

  static void _markNotificationAsSeen(
    String notificationId,
    DateTime sentAtUtc,
  ) {
    if (notificationId.trim().isEmpty) {
      return;
    }
    _seenAtUtcMillis[notificationId] = sentAtUtc.toUtc().millisecondsSinceEpoch;
    _pruneSeenEntries();
  }

  static void _pruneSeenEntries() {
    final nowUtcMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
    final cutoffMillis = nowUtcMillis - _seenRetentionWindow.inMilliseconds;

    _seenAtUtcMillis.removeWhere(
      (_, sentAtMillis) => sentAtMillis < cutoffMillis,
    );

    if (_seenAtUtcMillis.length <= _maxSeenEntries) {
      return;
    }

    final sortedEntries = _seenAtUtcMillis.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final overflow = _seenAtUtcMillis.length - _maxSeenEntries;
    for (var i = 0; i < overflow; i++) {
      _seenAtUtcMillis.remove(sortedEntries[i].key);
    }
  }

  Future<void> _syncReminderStateFromFirestore() async {
    if (kIsWeb) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await _loadState();

    final unreadSnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    final unreadIds = <String>{};
    for (final doc in unreadSnapshot.docs) {
      unreadIds.add(doc.id);
    }

    final scheduledIds = _scheduledReminderIds.keys.toList();
    for (final notificationId in scheduledIds) {
      if (!unreadIds.contains(notificationId)) {
        await _cancelReminderNotifications(
          notificationId,
          includePrimaryNotification: true,
        );
      }
    }

    for (final doc in unreadSnapshot.docs) {
      final data = doc.data();
      final payload = NotificationPayload(
        type: NotificationPayload.vehicleAlertType,
        notificationId: doc.id,
        title: _titleFromReason((data['reason'] ?? '').toString()),
        body: _bodyFromMessage((data['message'] ?? '').toString()),
        reason: (data['reason'] ?? NotificationPayload.defaultReason)
            .toString(),
        sentAtUtc: _extractSentAtUtc(data),
      );
      await _scheduleReminders(payload);
    }

    await _persistState();
  }

  static String _titleFromReason(String reason) {
    switch (reason.trim()) {
      case 'blocking_driveway':
        return 'Blocking driveway';
      case 'illegal_parking':
        return 'Illegal parking';
      case 'blocking_traffic':
        return 'Blocking traffic';
      case 'double_parked':
        return 'Double parked';
      case 'emergency':
        return 'Emergency alert';
      case 'private_property':
        return 'Private property alert';
      default:
        return NotificationPayload.defaultTitle;
    }
  }

  static String _bodyFromMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return NotificationPayload.defaultBody;
    }
    return trimmed;
  }

  static DateTime _extractSentAtUtc(Map<String, dynamic> data) {
    final sentAt = data['sentAt'];
    if (sentAt is Timestamp) {
      return sentAt.toDate().toUtc();
    }
    final parsed = DateTime.tryParse((sentAt ?? '').toString());
    if (parsed != null) {
      return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }

  static Future<void> _loadState() async {
    if (_stateLoaded || kIsWeb) {
      return;
    }

    _stateLoaded = true;
    try {
      final file = await _getStateFile();
      if (!await file.exists()) {
        return;
      }

      final rawJson = await file.readAsString();
      if (rawJson.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final seenMap = decoded['seen'];
      if (seenMap is Map<String, dynamic>) {
        for (final entry in seenMap.entries) {
          final timestamp = int.tryParse(entry.value.toString());
          if (timestamp != null) {
            _seenAtUtcMillis[entry.key] = timestamp;
          }
        }
      }

      final scheduledMap = decoded['scheduled'];
      if (scheduledMap is Map<String, dynamic>) {
        for (final entry in scheduledMap.entries) {
          final value = entry.value;
          if (value is! List) {
            continue;
          }
          final ids = value
              .map((item) => int.tryParse(item.toString()))
              .whereType<int>()
              .toList();
          if (ids.isNotEmpty) {
            _scheduledReminderIds[entry.key] = ids;
          }
        }
      }
      _pruneSeenEntries();
    } catch (e) {
      debugPrint('Failed to load notification state: $e');
    }
  }

  static Future<void> _persistState() async {
    if (kIsWeb) {
      return;
    }

    try {
      final file = await _getStateFile();
      final payload = <String, dynamic>{
        'seen': _seenAtUtcMillis,
        'scheduled': _scheduledReminderIds,
      };
      await file.writeAsString(jsonEncode(payload), flush: true);
    } catch (e) {
      debugPrint('Failed to persist notification state: $e');
    }
  }

  static Future<File> _getStateFile() async {
    if (_stateFile != null) {
      return _stateFile!;
    }
    final supportDir = await getApplicationSupportDirectory();
    _stateFile = File('${supportDir.path}/$_stateFileName');
    return _stateFile!;
  }
}
