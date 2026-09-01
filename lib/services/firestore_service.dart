import '../l10n/l10n_global.dart';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/alert_reply.dart';
import '../models/alert_wallet.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../utils/qr_payload_builder.dart';
import 'shared_stream.dart';


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Live listeners, keyed by what they are watching. See [SharedStream] for
  /// why they replay their last value rather than being plain broadcasts.
  ///
  /// Static because every screen builds its own `FirestoreService()` — that is
  /// the existing convention and worth keeping, since the class is stateless
  /// apart from this. The cache has to outlive the instances for the sharing
  /// to mean anything.
  static final Map<String, SharedStream<Object?>> _sharedStreams = {};

  Stream<T> _shared<T>(String key, Stream<T> Function() open) {
    final existing = _sharedStreams[key];
    if (existing != null) return existing.stream.cast<T>();

    final shared = SharedStream<Object?>(open().cast<Object?>());
    _sharedStreams[key] = shared;
    return shared.stream.cast<T>();
  }

  /// Drops every shared listener.
  ///
  /// Called on sign-out. Without it the previous account's document listeners
  /// stay open against rules that now deny them, which surfaces as a stream of
  /// permission-denied errors from a user who is no longer there.
  static Future<void> disposeSharedStreams() async {
    final streams = _sharedStreams.values.toList(growable: false);
    _sharedStreams.clear();
    for (final stream in streams) {
      await stream.dispose();
    }
  }

  CollectionReference<Map<String, dynamic>> _vehiclesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('vehicles');
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Error getting user data: $e');
      return null;
    }
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String userId) {
    return _shared(
      'user:$userId',
      () => _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null),
    );
  }

  /// The owner's alert budget, live.
  ///
  /// Lives on `users/{uid}` rather than in its own document so that the alert
  /// path — which already reads the user doc for `fcmToken` — spends no extra
  /// read deciding whether the alert is metered. The fields are server-written
  /// and the rules forbid the client from touching them; this stream is a
  /// read-only view for the UI.
  ///
  /// Errors are folded into an empty wallet rather than surfaced. A wallet that
  /// fails to load must not be allowed to read as "you have no alerts left" —
  /// [AlertWallet.empty] is a fresh cycle with the free allowance intact, which
  /// is the safe direction to be wrong in. The server holds the real number.
  Stream<AlertWallet> streamAlertWallet(String userId) {
    // Shares the *same* underlying listener as [streamUserData] would like to,
    // but cannot: they map the same document to different types. One extra
    // listener rather than one per screen is the win that matters.
    return _shared(
      'wallet:$userId',
      () => _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) => AlertWallet.fromMap(doc.data()))
          .handleError((Object e) {
            log('Error streaming alert wallet: $e');
          }),
    );
  }

  Future<AlertWallet> getAlertWallet(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return AlertWallet.fromMap(doc.data());
    } catch (e) {
      log('Error reading alert wallet: $e');
      return AlertWallet.empty;
    }
  }

  // Stream vehicles for user
  Stream<List<VehicleModel>> streamUserVehicles(String userId) {
    return _shared(
      'vehicles:$userId',
      () => _vehiclesRef(userId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => VehicleModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  Future<List<VehicleModel>> getUserVehicles(String userId) async {
    try {
      final snapshot = await _vehiclesRef(
        userId,
      ).orderBy('createdAt', descending: false).get();
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user vehicles: $e');
      return [];
    }
  }

  Future<VehicleModel> upsertVehicle({
    required String userId,
    required VehicleModel vehicle,
    bool setPrimaryIfMissing = false,
    bool syncLegacyUserFields = false,
  }) async {
    try {
      final vehicleRef = vehicle.id.trim().isEmpty
          ? _vehiclesRef(userId).doc()
          : _vehiclesRef(userId).doc(vehicle.id.trim());

      final normalizedLicensePlate = vehicle.licensePlate.trim();
      final normalizedAssetNumber = vehicle.assetNumber.trim().isEmpty
          ? normalizedLicensePlate
          : vehicle.assetNumber.trim();

      final vehicleData = <String, dynamic>{
        'userId': userId,
        'color': vehicle.color.trim(),
        'carModel': vehicle.carModel.trim(),
        'licensePlate': normalizedLicensePlate,
        'assetNumber': normalizedAssetNumber,
        'qrCodeId': vehicle.qrCodeId.trim(),
        'isActive': vehicle.isActive,
        'notificationsEnabled': vehicle.notificationsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (vehicle.id.trim().isEmpty) {
        vehicleData['createdAt'] = FieldValue.serverTimestamp();
      } else if (vehicle.createdAt != null) {
        vehicleData['createdAt'] = Timestamp.fromDate(vehicle.createdAt!);
      }

      final batch = _firestore.batch();
      batch.set(vehicleRef, vehicleData, SetOptions(merge: true));

      if (syncLegacyUserFields) {
        batch.set(_firestore.collection('users').doc(userId), {
          'carDetails': {
            'color': vehicle.color.trim(),
            'carModel': vehicle.carModel.trim(),
            'licensePlate': normalizedLicensePlate,
            'assetNumber': normalizedAssetNumber,
          },
          if (vehicle.qrCodeId.trim().isNotEmpty)
            'qrCodeId': vehicle.qrCodeId.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (setPrimaryIfMissing) {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await userRef.get();
        final currentPrimary = (userDoc.data()?['primaryVehicleId'] ?? '')
            .toString()
            .trim();
        if (currentPrimary.isEmpty) {
          await userRef.set({
            'primaryVehicleId': vehicleRef.id,
          }, SetOptions(merge: true));
        }
      }

      return vehicle.copyWith(
        id: vehicleRef.id,
        userId: userId,
        licensePlate: normalizedLicensePlate,
        assetNumber: normalizedAssetNumber,
      );
    } catch (e) {
      debugPrint('Error upserting vehicle: $e');
      throw appL10n.errSaveVehicle;
    }
  }

  Future<void> deleteVehicle(String userId, String vehicleId) async {
    try {
      final vehicleRef = _vehiclesRef(userId).doc(vehicleId);
      final vehicleDoc = await vehicleRef.get();
      final vehicleData = vehicleDoc.data();
      final qrCodeId = (vehicleData?['qrCodeId'] ?? '').toString().trim();

      final batch = _firestore.batch();
      if (qrCodeId.isNotEmpty) {
        batch.delete(_firestore.collection('qrCodes').doc(qrCodeId));
      }
      batch.delete(vehicleRef);
      await batch.commit();

      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final currentPrimary = (userDoc.data()?['primaryVehicleId'] ?? '')
          .toString()
          .trim();

      if (currentPrimary == vehicleId) {
        final remaining = await _vehiclesRef(
          userId,
        ).orderBy('createdAt', descending: false).limit(1).get();
        final replacementId = remaining.docs.isNotEmpty
            ? remaining.docs.first.id
            : '';
        await userRef.set({
          'primaryVehicleId': replacementId,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      throw appL10n.errDeleteVehicle;
    }
  }

  Future<void> setPrimaryVehicle({
    required String userId,
    required String vehicleId,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'primaryVehicleId': vehicleId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error setting primary vehicle: $e');
      throw appL10n.errSetPrimary;
    }
  }

  VehicleModel buildLegacyVehicleFromUser(UserModel user) {
    final details = user.legacyCarDetailsNormalized;
    return VehicleModel(
      id: '',
      userId: user.id,
      color: (details['color'] ?? '').toString(),
      carModel: (details['carModel'] ?? '').toString(),
      licensePlate: (details['licensePlate'] ?? '').toString(),
      assetNumber: (details['assetNumber'] ?? '').toString(),
      qrCodeId: user.qrCodeId.trim(),
      isActive: user.notificationsEnabled,
      notificationsEnabled: user.notificationsEnabled,
    );
  }

  Future<VehicleModel?> bootstrapVehiclesFromLegacyUser(UserModel user) async {
    try {
      final existing = await _vehiclesRef(user.id).limit(1).get();
      if (existing.docs.isNotEmpty) {
        return VehicleModel.fromFirestore(existing.docs.first);
      }

      final hasLegacyQr = user.qrCodeId.trim().isNotEmpty;
      if (!user.hasLegacyVehicleData && !hasLegacyQr) {
        return null;
      }

      final migratedVehicle = await upsertVehicle(
        userId: user.id,
        vehicle: buildLegacyVehicleFromUser(user),
        setPrimaryIfMissing: true,
        syncLegacyUserFields: true,
      );

      if (migratedVehicle.qrCodeId.trim().isNotEmpty) {
        await syncVehicleQrMetadata(
          user: user,
          vehicle: migratedVehicle,
          isActive: user.notificationsEnabled,
        );
      }

      return migratedVehicle;
    } catch (e) {
      debugPrint('Error bootstrapping legacy vehicle: $e');
      return null;
    }
  }

  Future<String> ensureVehicleQrCode({
    required UserModel user,
    required VehicleModel vehicle,
    bool syncLegacyUserFields = true,
  }) async {
    if (vehicle.id.trim().isEmpty) {
      throw 'Vehicle ID is required before generating a QR code';
    }

    if (vehicle.qrCodeId.trim().isNotEmpty) {
      return QrPayloadBuilder.buildPayload(user: user, vehicle: vehicle);
    }

    try {
      final qrCodeRef = _firestore.collection('qrCodes').doc();
      final updatedVehicle = vehicle.copyWith(qrCodeId: qrCodeRef.id);
      final metadata = QrPayloadBuilder.buildMetadata(
        user: user,
        vehicle: updatedVehicle,
      );
      final payload = QrPayloadBuilder.buildPayload(
        user: user,
        vehicle: updatedVehicle,
      );

      final batch = _firestore.batch();

      batch.set(_vehiclesRef(user.id).doc(updatedVehicle.id), {
        'qrCodeId': updatedVehicle.qrCodeId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (syncLegacyUserFields) {
        batch.set(_firestore.collection('users').doc(user.id), {
          'qrCodeId': updatedVehicle.qrCodeId,
          'carDetails': {
            'color': updatedVehicle.color,
            'carModel': updatedVehicle.carModel,
            'licensePlate': updatedVehicle.licensePlate,
            'assetNumber': updatedVehicle.assetNumber,
          },
          if (user.primaryVehicleId.trim().isEmpty)
            'primaryVehicleId': updatedVehicle.id,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      batch.set(qrCodeRef, {
        'metadata': metadata,
        'payload': payload,
        'shareableLink': FieldValue.delete(),
        'userId': user.id,
        'vehicleId': updatedVehicle.id,
        'isActive': updatedVehicle.isActive,
        'payloadVersion': metadata['payloadVersion'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      return payload;
    } catch (e) {
      debugPrint('Error creating QR code for vehicle: $e');
      rethrow;
    }
  }

  Future<void> syncVehicleQrMetadata({
    required UserModel user,
    required VehicleModel vehicle,
    bool? isActive,
  }) async {
    if (vehicle.qrCodeId.trim().isEmpty) {
      return;
    }

    try {
      final metadata = QrPayloadBuilder.buildMetadata(
        user: user,
        vehicle: vehicle,
      );
      final payload = QrPayloadBuilder.buildPayload(
        user: user,
        vehicle: vehicle,
      );

      await _firestore.collection('qrCodes').doc(vehicle.qrCodeId).set({
        'metadata': metadata,
        'payload': payload,
        'shareableLink': FieldValue.delete(),
        'userId': user.id,
        'vehicleId': vehicle.id,
        'isActive': isActive ?? vehicle.isActive,
        'payloadVersion': metadata['payloadVersion'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing vehicle QR metadata: $e');
    }
  }

  Future<void> toggleVehicleQRCodeStatus({
    required String userId,
    required String vehicleId,
    required String qrCodeId,
    required bool isActive,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.set(_vehiclesRef(userId).doc(vehicleId), {
        'isActive': isActive,
        'notificationsEnabled': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (qrCodeId.trim().isNotEmpty) {
        batch.set(_firestore.collection('qrCodes').doc(qrCodeId), {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error toggling vehicle QR code status: $e');
      throw appL10n.errQrStatus;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? phoneNumber,
    Map<String, dynamic>? carDetails,
    bool? notificationsEnabled,
    String? primaryVehicleId,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }

      if (carDetails != null) {
        updates['carDetails'] = carDetails;
      }

      if (notificationsEnabled != null) {
        updates['notificationsEnabled'] = notificationsEnabled;
      }

      if (primaryVehicleId != null) {
        updates['primaryVehicleId'] = primaryVehicleId;
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw appL10n.errUpdateProfile;
    }
  }

  // Get QR code data
  Future<Map<String, dynamic>?> getQRCodeData(String qrCodeId) async {
    try {
      final doc = await _firestore.collection('qrCodes').doc(qrCodeId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting QR code data: $e');
      return null;
    }
  }

  // Legacy wrapper
  Future<String> createQRCodeForUser(UserModel user) async {
    final vehicles = await getUserVehicles(user.id);
    VehicleModel vehicle;

    if (vehicles.isNotEmpty) {
      final preferred = vehicles
          .where((v) => v.id == user.primaryVehicleId)
          .toList();
      vehicle = preferred.isNotEmpty ? preferred.first : vehicles.first;
    } else {
      vehicle = await upsertVehicle(
        userId: user.id,
        vehicle: buildLegacyVehicleFromUser(user),
        setPrimaryIfMissing: true,
        syncLegacyUserFields: true,
      );
    }

    final payload = await ensureVehicleQrCode(
      user: user,
      vehicle: vehicle,
      syncLegacyUserFields: true,
    );
    await syncVehicleQrMetadata(user: user, vehicle: vehicle);
    return payload;
  }

  // Legacy wrapper
  Future<void> syncQRCodeMetadata({
    required String qrCodeId,
    required Map<String, dynamic> metadata,
    String? shareableLink,
    String? payload,
  }) async {
    try {
      final payloadValue = payload?.trim();
      final shareableLinkValue = shareableLink?.trim();
      final shouldWriteShareableLink =
          shareableLinkValue != null &&
          shareableLinkValue.isNotEmpty &&
          shareableLinkValue != payloadValue;

      await _firestore.collection('qrCodes').doc(qrCodeId).set({
        'metadata': metadata,
        if (payload != null) 'payload': payload,
        if (!shouldWriteShareableLink &&
            (payload != null || shareableLink != null))
          'shareableLink': FieldValue.delete(),
        if (shouldWriteShareableLink) 'shareableLink': shareableLinkValue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing QR code metadata: $e');
    }
  }

  // Legacy wrapper
  Future<void> toggleQRCodeStatus({
    required String qrCodeId,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('qrCodes').doc(qrCodeId).update({
        'isActive': isActive,
      });
    } catch (e) {
      debugPrint('Error toggling QR code status: $e');
      throw appL10n.errQrStatus;
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _shared(
      'notifications:$userId',
      () => _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  Stream<List<NotificationModel>> streamVehicleNotifications({
    required String userId,
    required String vehicleId,
  }) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get notification by ID
  Future<NotificationModel?> getNotification(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return NotificationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting notification: $e');
      return null;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Delete notification
  /// Records the owner's reply to an alert.
  ///
  /// This is the only write in the app that a stranger will read. It goes to
  /// `notifications/{id}`, and the scan page — which is still open in
  /// somebody's hand a few metres from the vehicle — polls for it through
  /// `/api/status`. Nothing about the owner travels with it; the reply is an
  /// id from [AlertReply] and a timestamp, and the endpoint that serves it
  /// returns only those two things.
  ///
  /// Replying also marks the alert read, because it plainly is, and that is
  /// what stops the escalating reminders. Callers still cancel the local
  /// notification lifecycle themselves — this method only owns the document.
  ///
  /// Throws a human-readable string on failure, like every other user-initiated
  /// write here, because the owner is watching for confirmation that the person
  /// at their car has been told.
  Future<void> replyToNotification({
    required String notificationId,
    required AlertReply reply,
  }) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'acknowledgementEta': reply.id,
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error replying to notification: $e');
      throw appL10n.replyFailed;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw appL10n.errDeleteNotification;
    }
  }

  // Get notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting notification count: $e');
      return 0;
    }
  }

  // Stream unread notification count
  /// How many alerts are unread.
  ///
  /// Derived from [streamUserNotifications] rather than opening a second query
  /// against the same collection. The list is already live, already capped at
  /// 50, and already in memory — a separate `where('read', false)` listener was
  /// a second billed sync of substantially the same documents to answer a
  /// question the first one had already answered.
  ///
  /// The cap is the one behavioural difference: an owner with more than 50
  /// unread alerts sees "50", which is a number no badge renders anyway (the
  /// badge caps at 99+) and a situation that means something has gone very
  /// wrong regardless.
  Stream<int> streamUnreadNotificationCount(String userId) {
    return streamUserNotifications(
      userId,
    ).map((alerts) => alerts.where((alert) => !alert.read).length).distinct();
  }

  // Get notification statistics
  Future<Map<String, int>> getNotificationStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's notifications
      final todaySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where(
            'sentAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      // Get total notifications
      final totalSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'today': todaySnapshot.docs.length,
        'total': totalSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return {'today': 0, 'total': 0};
    }
  }

  // Mark every unread notification for a user as read.
  //
  // Returns the ids that were flipped so the caller can cancel their escalation
  // reminders — a notification the owner has acknowledged must stop nagging.
  Future<List<String>> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return const <String>[];
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      throw appL10n.errMarkRead;
    }
  }

  // Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      throw appL10n.errClearNotifications;
    }
  }
}
