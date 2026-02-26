import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String phoneNumber;
  final String fcmToken;
  final String primaryVehicleId;
  // Legacy single-QR field kept for backward compatibility.
  final String qrCodeId;
  final DateTime? createdAt;
  // Legacy single-vehicle field kept for backward compatibility.
  final Map<String, dynamic>? carDetails;
  final bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.email,
    this.phoneNumber = '',
    this.fcmToken = '',
    this.primaryVehicleId = '',
    this.qrCodeId = '',
    this.createdAt,
    this.carDetails,
    this.notificationsEnabled = true,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      fcmToken: data['fcmToken'] ?? '',
      primaryVehicleId: data['primaryVehicleId'] ?? '',
      qrCodeId: data['qrCodeId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      carDetails: data['carDetails'] as Map<String, dynamic>?,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
      'primaryVehicleId': primaryVehicleId,
      'qrCodeId': qrCodeId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'carDetails': carDetails,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  // Copy with method for updating specific fields
  UserModel copyWith({
    String? email,
    String? phoneNumber,
    String? fcmToken,
    String? primaryVehicleId,
    String? qrCodeId,
    DateTime? createdAt,
    Map<String, dynamic>? carDetails,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fcmToken: fcmToken ?? this.fcmToken,
      primaryVehicleId: primaryVehicleId ?? this.primaryVehicleId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      createdAt: createdAt ?? this.createdAt,
      carDetails: carDetails ?? this.carDetails,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  bool get hasLegacyVehicleData {
    if (carDetails == null || carDetails!.isEmpty) {
      return false;
    }
    final normalized = legacyCarDetailsNormalized;
    return normalized['licensePlate'].toString().isNotEmpty ||
        normalized['color'].toString().isNotEmpty ||
        normalized['carModel'].toString().isNotEmpty;
  }

  Map<String, dynamic> get legacyCarDetailsNormalized {
    final details = carDetails ?? {};
    return {
      'color': (details['color'] ?? '').toString().trim(),
      'carModel': (details['carModel'] ?? '').toString().trim(),
      'licensePlate': (details['licensePlate'] ?? '').toString().trim(),
      'assetNumber': (details['assetNumber'] ?? details['licensePlate'] ?? '')
          .toString()
          .trim(),
    };
  }

  // Get formatted car details
  String get carDescription {
    if (carDetails == null || carDetails!.isEmpty) {
      return 'No car details added';
    }

    final List<String> details = [];

    if (carDetails!['color'] != null && carDetails!['color'].isNotEmpty) {
      details.add(carDetails!['color']);
    }

    if (carDetails!['carModel'] != null && carDetails!['carModel'].isNotEmpty) {
      details.add(carDetails!['carModel']);
    }

    if (carDetails!['licensePlate'] != null &&
        carDetails!['licensePlate'].isNotEmpty) {
      details.add('(${carDetails!['licensePlate']})');
    }

    return details.isEmpty ? 'No car details added' : details.join(' ');
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, phoneNumber: $phoneNumber, primaryVehicleId: $primaryVehicleId, qrCodeId: $qrCodeId, notificationsEnabled: $notificationsEnabled)';
  }
}
