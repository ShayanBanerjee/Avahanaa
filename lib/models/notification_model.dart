import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String qrCodeId;
  final String userId;
  final String vehicleId;
  final String reason;
  final String message;
  final DateTime sentAt;
  final String status;
  final bool read;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.qrCodeId,
    required this.userId,
    this.vehicleId = '',
    required this.reason,
    required this.message,
    required this.sentAt,
    this.status = 'sent',
    this.read = false,
    this.readAt,
  });

  // Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      qrCodeId: data['qrCodeId'] ?? '',
      userId: data['userId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      reason: data['reason'] ?? '',
      message: data['message'] ?? '',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'sent',
      read: data['read'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert NotificationModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'qrCodeId': qrCodeId,
      'userId': userId,
      'vehicleId': vehicleId,
      'reason': reason,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status,
      'read': read,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Copy with method
  NotificationModel copyWith({
    String? qrCodeId,
    String? userId,
    String? vehicleId,
    String? reason,
    String? message,
    DateTime? sentAt,
    String? status,
    bool? read,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      reason: reason ?? this.reason,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
    );
  }

  // Get formatted reason text
  String get reasonText {
    switch (reason) {
      case 'blocking_driveway':
        return 'Blocking Driveway';
      case 'illegal_parking':
        return 'Illegal Parking';
      case 'blocking_traffic':
        return 'Blocking Traffic';
      case 'double_parked':
        return 'Double Parked';
      case 'emergency':
        return 'Emergency';
      case 'private_property':
        return 'Private Property';
      case 'other':
        return 'Other';
      default:
        return 'Vehicle Notification';
    }
  }

  // Get reason icon
  String get reasonIcon {
    switch (reason) {
      case 'blocking_driveway':
        return '🚪';
      case 'illegal_parking':
        return '⚠️';
      case 'blocking_traffic':
        return '🚦';
      case 'double_parked':
        return '🚗';
      case 'emergency':
        return '🚨';
      case 'private_property':
        return '🏠';
      case 'other':
        return '📝';
      default:
        return '🚗';
    }
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, reason: $reason, sentAt: $sentAt)';
  }
}
