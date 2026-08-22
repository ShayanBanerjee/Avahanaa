import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// How each alert reason is drawn.
///
/// The reason strings are set by the out-of-repo scan page, so this mapping
/// must degrade gracefully: an unrecognised reason still gets a sensible icon
/// and colour rather than a blank tile.
///
/// Icons replaced the previous emoji: emoji render differently on every
/// Android version and vendor skin, which made the inbox look inconsistent and
/// made the severity impossible to read at a glance.
class ReasonVisual {
  const ReasonVisual({
    required this.icon,
    required this.color,
    required this.severity,
  });

  final IconData icon;
  final Color color;

  /// 2 = drop everything, 1 = go now, 0 = informational.
  final int severity;

  bool get isUrgent => severity >= 2;

  static ReasonVisual of(String reason) {
    switch (reason) {
      case 'emergency':
        return const ReasonVisual(
          icon: Icons.emergency_rounded,
          color: AppColors.alert,
          severity: 2,
        );
      case 'blocking_driveway':
        return const ReasonVisual(
          icon: Icons.garage_rounded,
          color: AppColors.alert,
          severity: 2,
        );
      case 'blocking_traffic':
        return const ReasonVisual(
          icon: Icons.traffic_rounded,
          color: AppColors.alert,
          severity: 2,
        );
      case 'illegal_parking':
        return const ReasonVisual(
          icon: Icons.local_police_rounded,
          color: AppColors.warning,
          severity: 1,
        );
      case 'double_parked':
        return const ReasonVisual(
          icon: Icons.directions_car_rounded,
          color: AppColors.warning,
          severity: 1,
        );
      case 'private_property':
        return const ReasonVisual(
          icon: Icons.home_rounded,
          color: AppColors.warning,
          severity: 1,
        );
      case 'other':
        return const ReasonVisual(
          icon: Icons.chat_bubble_rounded,
          color: AppColors.primary,
          severity: 0,
        );
      default:
        return const ReasonVisual(
          icon: Icons.notifications_rounded,
          color: AppColors.primary,
          severity: 0,
        );
    }
  }

  /// A short line telling the owner what this actually means for them.
  static String guidance(String reason) {
    switch (reason) {
      case 'emergency':
        return 'Treat this as urgent. Get to your vehicle now.';
      case 'blocking_driveway':
        return 'Someone cannot get in or out. Move your vehicle soon.';
      case 'blocking_traffic':
        return 'Your vehicle is holding up traffic. Move it soon.';
      case 'illegal_parking':
        return 'Your vehicle may be towed or fined. Check on it.';
      case 'double_parked':
        return 'You are boxing someone in. They are waiting.';
      case 'private_property':
        return 'You are parked on private land. You may be asked to move.';
      default:
        return 'Someone at your vehicle wanted you to know.';
    }
  }
}
