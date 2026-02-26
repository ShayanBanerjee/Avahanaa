import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../utils/qr_payload_builder.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Stream vehicles for user
  Stream<List<VehicleModel>> streamUserVehicles(String userId) {
    return _vehiclesRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VehicleModel.fromFirestore(doc))
              .toList(),
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
      throw 'Failed to save vehicle';
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
      throw 'Failed to delete vehicle';
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
      throw 'Failed to set primary vehicle';
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
      throw 'Failed to update QR code status';
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
      throw 'Failed to update profile';
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
      throw 'Failed to update QR code status';
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
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
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      throw 'Failed to delete notification';
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
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
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
      throw 'Failed to clear notifications';
    }
  }
}
