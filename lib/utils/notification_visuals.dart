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

  /// The accent, as **ink** — the icon glyph, the unread rail. Follows the
  /// theme, so it is lifted at night to stay legible on a dark ground.
  final Color color;

  /// The accent as a **fill**, with white text on top of it — the header band
  /// on the detail sheet, the panic banner.
  ///
  /// Fixed in both themes, and that is the whole point of it existing
  /// separately. The night palette lifts the accents so they can be read as
  /// ink on near-black; the same lift makes them far too pale to carry white
  /// text. The detail sheet's header ran white on `#63A4FF` at 2.2:1 before
  /// this split.
  Color get fill => switch (color) {
    _ when severity >= 2 => const Color(0xFFC81B30),
    _ when severity == 1 => const Color(0xFFB45309),
    _ => const Color(0xFF2563EB),
  };

  /// 2 = drop everything, 1 = go now, 0 = informational.
  final int severity;

  bool get isUrgent => severity >= 2;

  static ReasonVisual of(String reason) {
    switch (reason) {
      case 'emergency':
        return ReasonVisual(
          icon: Icons.emergency_rounded,
          color: AppColors.alert,
          severity: 2,
        );
      case 'blocking_driveway':
        return ReasonVisual(
          icon: Icons.garage_rounded,
          color: AppColors.alert,
          severity: 2,
        );
      case 'blocking_traffic':
        return ReasonVisual(
          icon: Icons.traffic_rounded,
          color: AppColors.alert,
          severity: 2,
        );
      case 'illegal_parking':
        return ReasonVisual(
          icon: Icons.local_police_rounded,
          color: AppColors.warning,
          severity: 1,
        );
      case 'double_parked':
        return ReasonVisual(
          icon: Icons.directions_car_rounded,
          color: AppColors.warning,
          severity: 1,
        );
      case 'private_property':
        return ReasonVisual(
          icon: Icons.home_rounded,
          color: AppColors.warning,
          severity: 1,
        );
      case 'other':
        return ReasonVisual(
          icon: Icons.chat_bubble_rounded,
          color: AppColors.primary,
          severity: 0,
        );
      default:
        return ReasonVisual(
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
