import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
      // Severity 0, deliberately, even though the push itself arrives at full
      // alarm strength. The alarm is the thing being tested; the row in the
      // inbox afterwards is not an emergency and dressing it in alert red would
      // teach people to discount the colour that matters.
      case 'test':
        return ReasonVisual(
          icon: Icons.notifications_active_rounded,
          color: AppColors.success,
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

  /// The reason as a short noun phrase, in the reader's language.
  ///
  /// Distinct from [guidanceIn], which is the instruction. This is the label —
  /// what to call the thing in a list or a breakdown, where a full sentence
  /// would not fit and would read oddly beside a count.
  ///
  /// Delegates to the same strings `NotificationModel.reasonTextIn` uses, so
  /// there is one translation of each reason rather than two that can drift.
  static String labelIn(AppL10n l10n, String reason) {
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
      case 'test':
        return l10n.reasonTest;
      case 'other':
        return l10n.reasonOther;
      default:
        return l10n.reasonUnknown;
    }
  }

  /// A short line telling the owner what this actually means for them.
  /// The one-line instruction, in the reader's language.
  static String guidanceIn(AppL10n l10n, String reason) {
    switch (reason) {
      case 'emergency':
        return l10n.guidanceEmergency;
      case 'blocking_driveway':
        return l10n.guidanceBlockingDriveway;
      case 'blocking_traffic':
        return l10n.guidanceBlockingTraffic;
      case 'illegal_parking':
        return l10n.guidanceIllegalParking;
      case 'double_parked':
        return l10n.guidanceDoubleParked;
      case 'private_property':
        return l10n.guidancePrivateProperty;
      case 'test':
        return l10n.guidanceTest;
      default:
        return l10n.guidanceOther;
    }
  }

  /// English, for logs and background-isolate notification text.
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
      case 'test':
        return 'You asked for this one. A real alert arrives exactly like it.';
      default:
        return 'Someone at your vehicle wanted you to know.';
    }
  }
}
