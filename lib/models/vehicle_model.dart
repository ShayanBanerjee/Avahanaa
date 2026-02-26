import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String userId;
  final String color;
  final String carModel;
  final String licensePlate;
  final String assetNumber;
  final String qrCodeId;
  final bool isActive;
  final bool notificationsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VehicleModel({
    required this.id,
    required this.userId,
    this.color = '',
    this.carModel = '',
    this.licensePlate = '',
    this.assetNumber = '',
    this.qrCodeId = '',
    this.isActive = true,
    this.notificationsEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return VehicleModel.fromMap(id: doc.id, data: data);
  }

  factory VehicleModel.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return VehicleModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      color: (data['color'] ?? '').toString(),
      carModel: (data['carModel'] ?? '').toString(),
      licensePlate: (data['licensePlate'] ?? '').toString(),
      assetNumber: (data['assetNumber'] ?? '').toString(),
      qrCodeId: (data['qrCodeId'] ?? '').toString(),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      notificationsEnabled: data['notificationsEnabled'] is bool
          ? data['notificationsEnabled'] as bool
          : true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'color': color.trim(),
      'carModel': carModel.trim(),
      'licensePlate': licensePlate.trim(),
      'assetNumber': assetNumber.trim(),
      'qrCodeId': qrCodeId.trim(),
      'isActive': isActive,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  VehicleModel copyWith({
    String? id,
    String? userId,
    String? color,
    String? carModel,
    String? licensePlate,
    String? assetNumber,
    String? qrCodeId,
    bool? isActive,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      carModel: carModel ?? this.carModel,
      licensePlate: licensePlate ?? this.licensePlate,
      assetNumber: assetNumber ?? this.assetNumber,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      isActive: isActive ?? this.isActive,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get description {
    final parts = <String>[];
    if (color.trim().isNotEmpty) {
      parts.add(color.trim());
    }
    if (carModel.trim().isNotEmpty) {
      parts.add(carModel.trim());
    }
    if (licensePlate.trim().isNotEmpty) {
      parts.add('(${licensePlate.trim()})');
    }
    return parts.isEmpty ? 'No vehicle details added' : parts.join(' ');
  }
}
