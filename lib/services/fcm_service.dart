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
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/alert_reply.dart';
import 'notification_payload.dart';

@pragma('vm:entry-point')
/// Runs in a background isolate when the notification is acted on while the app
/// is not in the foreground.
///
/// A plain tap is still handled in the main isolate via
/// `getNotificationAppLaunchDetails()` — the app is being opened anyway. What
/// has to happen *here* is the reply, because the entire point of a lock-screen
/// action is that the app never opens.
///
/// This isolate has nothing: no Firebase, no `main()`, no widget tree. It has
/// to bootstrap everything it needs and finish quickly, and it must not throw —
/// an uncaught error here is invisible to the user, who will believe they told
/// somebody they were coming.
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  final actionId = response.actionId;
  if (actionId == null || !actionId.startsWith(FCMService.replyActionPrefix)) {
    // A plain tap. The main isolate picks it up on launch.
    return;
  }
  unawaited(FCMService.replyFromNotificationAction(response));
}

class FCMService {
  static const Duration _reminderDelayOne = Duration(minutes: 3);
  static const Duration _reminderDelayTwo = Duration(minutes: 15);
  static const Duration _seenRetentionWindow = Duration(days: 7);
  static const int _maxSeenEntries = 500;
  static const String _stateFileName =
      'avahanaa_notification_orchestrator_state_v1.json';

  /// The loud channel.
  ///
  /// `_v3` rather than a change to `_v2`, because a channel's sound and
  /// importance are frozen the moment Android creates it — an existing install
  /// would keep the old default tone forever. A new id is the only way to
  /// change how an alert sounds, and it costs the user's per-channel settings,
  /// so do not do it casually.
  ///
  /// The alarm stream is deliberate. This fires when a stranger is standing at
  /// the owner's car; the notification tone the phone uses for a promotional
  /// email is the wrong instrument. `avahanaa_alarm.wav` shipped in
  /// `assets/audio/` for months without being referenced by anything — this is
  /// the feature it was added for.
  ///
  /// **Review-visible.** Alarm-stream audio and full-screen intent are both
  /// things Play looks at. See docs/play_store_compliance.md before touching
  /// this, and ship changes to it in an isolated release.
  static final AndroidNotificationChannel _criticalChannel =
      AndroidNotificationChannel(
        'avahanaa_critical_alerts_v3',
        'Avahanaa Critical Alerts',
        description:
            'Someone is at your vehicle. Loud by design — these are the alerts '
            'you asked to be interrupted for.',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('avahanaa_alarm'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        enableLights: true,
      );

  /// The previous critical channel.
  ///
  /// Still created, and still cancelled against, because an install that
  /// upgrades mid-alert has notifications posted on it. Nothing new is sent
  /// here.
  static final AndroidNotificationChannel _criticalChannelV2 =
      AndroidNotificationChannel(
        'avahanaa_critical_alerts_v2',
        'Avahanaa Critical Alerts (previous)',
        description: 'Critical vehicle alerts that require quick action',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  /// Where an alert lands once the owner's alert budget is spent.
  ///
  /// A real channel at default importance: it makes the phone's ordinary
  /// notification sound once and then sits in the shade. It carries the alert's
  /// own words — the reason someone scanned, and whatever they typed — because
  /// hiding that behind an upsell would be withholding the thing the owner
  /// actually needs. What it withholds is the *urgency*: no alarm tone, no
  /// screen takeover, no escalating reminders.
  ///
  /// It has to be a separate channel rather than the alert channel posted at
  /// lower priority. Android freezes a channel's importance the moment it is
  /// created and lets the user own it thereafter; a sender cannot turn one
  /// down. Two channels is the only way the distinction survives.
  static final AndroidNotificationChannel _quietChannel =
      AndroidNotificationChannel(
        'avahanaa_quiet_notices_v1',
        'Avahanaa Notices',
        description:
            'Alerts that arrive when your alert credits have run out, and '
            'other non-urgent notices.',
        importance: Importance.defaultImportance,
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
    await androidPlugin?.createNotificationChannel(_criticalChannelV2);
    await androidPlugin?.createNotificationChannel(_criticalChannel);
    await androidPlugin?.createNotificationChannel(_quietChannel);

    // Asked for, never assumed. On Android 14+ this is only default-granted to
    // apps whose core function is calling or alarms, and Avahanaa is neither.
    // A refusal is fine: the alert still arrives as a heads-up on a
    // max-importance channel, which is exactly what shipped before this.
    await androidPlugin?.requestFullScreenIntentPermission();

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
    // A reply action taken while the app happens to be running. Same write as
    // the background isolate, and it must not also deep-link into the alert —
    // the owner answered from the shade precisely so they would not have to
    // look at it.
    final actionId = response.actionId;
    if (actionId != null && actionId.startsWith(replyActionPrefix)) {
      unawaited(replyFromNotificationAction(response));
      return;
    }

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
    // The escalating ladder is the loud half of the product, and it is the half
    // the alert budget actually meters. A quiet notice arrives once and then
    // leaves the owner alone.
    if (payload.tier == AlertTier.full) {
      await _scheduleReminders(payload);
    }
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

  /// The replies offered on the notification itself.
  ///
  /// This is the whole point of the reply channel. The owner is asleep, or
  /// driving, or in a meeting; the alert wakes them and the answer that calms
  /// the person in the street is one tap away on the lock screen. Making them
  /// unlock, find the app and open a sheet is three steps too many for
  /// something that has to happen in seconds.
  ///
  /// Two actions, not five. Android shows at most three and truncates hard,
  /// and a lock screen is not a place to make a nuanced choice.
  static const String replyActionPrefix = 'avahanaa_reply_';

  static List<AndroidNotificationAction> _replyActions() {
    return const <AndroidNotificationAction>[
      AndroidNotificationAction(
        '${replyActionPrefix}omw_5',
        'On my way — 5 min',
        // Handled in the background isolate: no UI, no unlock, no app launch.
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        '${replyActionPrefix}omw_now',
        "I'm right here",
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ];
  }

  /// Sends the owner's reply from a notification action.
  ///
  /// Called from the background isolate, so it initialises Firebase itself and
  /// resolves the signed-in user from the persisted auth state rather than from
  /// anything the app is holding — there is no app.
  ///
  /// Deliberately writes straight to Firestore instead of going through
  /// `FirestoreService`: the offline queue in the Firestore SDK will hold this
  /// write and replay it when connectivity returns, which is the behaviour you
  /// want from a basement car park.
  static Future<void> replyFromNotificationAction(
    NotificationResponse response,
  ) async {
    final actionId = response.actionId;
    if (actionId == null || !actionId.startsWith(replyActionPrefix)) return;

    final replyId = actionId.substring(replyActionPrefix.length);
    final reply = AlertReply.fromId(replyId);
    if (reply == null) return;

    final payload = NotificationPayload.parseTapPayload(response.payload);
    if (payload == null) return;

    try {
      // Cheap when the isolate already has it, required when it does not.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(payload.notificationId)
          .update({
            'acknowledgedAt': FieldValue.serverTimestamp(),
            'acknowledgementEta': reply.id,
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });

      // Replying is reading. Stop the escalation ladder.
      await cancelNotificationLifecycleById(payload.notificationId);
      log('Replied "\${reply.id}" from the lock screen');
    } catch (e) {
      // Nothing to surface this on — there is no UI in this isolate. The alert
      // stays unread, so the reminders keep running, which is the safe failure:
      // the owner is nagged again rather than believing they answered.
      log('Lock-screen reply failed: \$e');
    }
  }

  static Future<void> _showImmediateNotification(
    NotificationPayload payload,
  ) async {
    if (payload.tier == AlertTier.quiet) {
      await _showQuietNotice(payload);
      return;
    }

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
          color: const Color(0xFFC81B30),
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          // Takes over the screen when the phone is locked. Degrades to an
          // ordinary heads-up when the permission was refused, which is why
          // nothing here depends on it.
          fullScreenIntent: true,
          actions: _replyActions(),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: payload.toLocalPayloadString(isReminder: false, reminderStep: 0),
    );
  }

  /// The same alert, without the alarm.
  ///
  /// Note what is kept: the title, the body, and the reply actions. Somebody
  /// whose budget has run out can still tell the person at their car that they
  /// are on the way, which is the half of the product that de-escalates the
  /// moment — metering that would be metering the wrong thing entirely.
  ///
  /// What is dropped: the alarm channel, the alarm audio usage, the full-screen
  /// intent, the heavy vibration, and the reminders.
  static Future<void> _showQuietNotice(NotificationPayload payload) async {
    await _localNotifications.show(
      NotificationReminderIds.primaryId(payload.notificationId),
      payload.title,
      payload.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _quietChannel.id,
          _quietChannel.name,
          channelDescription: _quietChannel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.private,
          styleInformation: BigTextStyleInformation(payload.body),
          icon: '@mipmap/launcher_icon',
          ticker: payload.title,
          color: const Color(0xFFF59E0B),
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          actions: _replyActions(),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
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
