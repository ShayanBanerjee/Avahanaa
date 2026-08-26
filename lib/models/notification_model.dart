import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';
import 'alert_reply.dart';

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

  /// When the owner replied. Null until they do.
  final DateTime? acknowledgedAt;

  /// Which reply they sent. See [AlertReply] — this is the wire value, kept as
  /// a raw string so an id written by a newer build round-trips unchanged
  /// instead of being flattened on read.
  final String acknowledgementEta;

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
    this.acknowledgedAt,
    this.acknowledgementEta = '',
  });

  /// The owner's reply, or null if they have not answered yet.
  AlertReply? get reply =>
      acknowledgedAt == null ? null : AlertReply.fromId(acknowledgementEta);

  /// Whether the scanner has been told someone is coming.
  bool get isAcknowledged => acknowledgedAt != null;

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
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      acknowledgementEta: data['acknowledgementEta'] ?? '',
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
      'acknowledgedAt':
          acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'acknowledgementEta': acknowledgementEta,
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
    DateTime? acknowledgedAt,
    String? acknowledgementEta,
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
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgementEta: acknowledgementEta ?? this.acknowledgementEta,
    );
  }

  // Get formatted reason text
  /// The reason, in the reader's language.
  ///
  /// Takes the localizations rather than reading them from a `BuildContext`,
  /// because this is a model — it is also read from a background isolate where
  /// there is no tree to look anything up in.
  String reasonTextIn(AppL10n l10n) {
    switch (reason) {
      case 'blocking_driveway':
        return l10n.reasonBlockingDriveway;
      case 'illegal_parking':
        return l10n.reasonIllegalParking;
      case 'blocking_traffic':
        return l10n.reasonBlockingTraffic;
      case 'double_parked':
        return l10n.reasonDoubleParked;
      case 'emergency':
        return l10n.reasonEmergency;
      case 'private_property':
        return l10n.reasonPrivateProperty;
      case 'other':
        return l10n.reasonOther;
      default:
        return l10n.reasonUnknown;
    }
  }

  /// The English reason, for logs and for the notification built in the
  /// background isolate before any locale is resolved.
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
  /// How long ago, in the reader's language.
  String timeAgoIn(AppL10n l10n) {
    final difference = DateTime.now().difference(sentAt);

    if (difference.inSeconds < 60) return l10n.timeJustNow;
    if (difference.inMinutes < 60) return l10n.timeMinutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l10n.timeHoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.timeDaysAgo(difference.inDays);
    // Past a week the exact date is more use than a count, and digits read the
    // same either way.
    return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
  }

  /// English, for logs.
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
