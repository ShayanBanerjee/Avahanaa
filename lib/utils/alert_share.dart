/// Hand an alert to somebody who is closer to the vehicle than you are.
///
/// The owner is in a meeting, or out of town, and their driver, spouse or
/// building watchman is two minutes from the car. Until now the only thing the
/// app could do about that was nothing.
///
/// This is deliberately the *pragmatic* version of trusted-contact escalation
/// rather than the built-in one. A real escalation feature needs a second
/// Avahanaa account, an invite, an acceptance, a revoke, and a scheduled job —
/// and it would still lose to the thing people already do, which is forward a
/// message on WhatsApp. This composes that message properly and gets out of
/// the way.
///
/// ## What it deliberately does not include
///
/// No QR id, no status token, no deep link. Those are capabilities: the token
/// lets the holder poll the scanner's reply channel, and the QR id identifies
/// the sticker. A forwarded message gets screenshotted and re-forwarded, and
/// anything in it should be assumed public.
///
/// What it does carry is what the helper actually needs: which vehicle, what
/// is wrong, when, and where — the same coarse coordinate the owner sees,
/// which is a parked car's location rather than a person's.
library;

import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/notification_model.dart';
import '../models/vehicle_model.dart';

abstract final class AlertShare {
  /// Composes the message and opens the system share sheet.
  ///
  /// Plain text on purpose. The destination is almost always WhatsApp, and
  /// anything richer than text either degrades badly or does not survive being
  /// forwarded on.
  static Future<void> forward({
    required AppL10n l10n,
    required NotificationModel alert,
    VehicleModel? vehicle,
    required String localTime,
  }) async {
    final lines = <String>[
      l10n.shareHeadline(alert.reasonTextIn(l10n)),
      '',
      if (vehicle != null) l10n.shareVehicle(_vehicleLabel(vehicle)),
      l10n.shareWhen(localTime),
    ];

    final message = alert.message.trim();
    if (message.isNotEmpty) {
      lines
        ..add('')
        ..add(l10n.shareTheySaid(message));
    }

    final location = alert.location;
    if (location != null) {
      lines
        ..add('')
        ..add(l10n.shareWhere)
        ..add(location.webMapUrl);
    }

    lines
      ..add('')
      ..add(l10n.shareFooter);

    await SharePlus.instance.share(
      ShareParams(
        text: lines.join('\n'),
        subject: l10n.shareHeadline(alert.reasonTextIn(l10n)),
      ),
    );
  }

  static String _vehicleLabel(VehicleModel vehicle) {
    final parts = <String>[
      if (vehicle.color.trim().isNotEmpty) vehicle.color.trim(),
      if (vehicle.carModel.trim().isNotEmpty) vehicle.carModel.trim(),
    ];
    final plate = vehicle.licensePlate.trim();
    final descriptor = parts.join(' ');
    if (descriptor.isEmpty) return plate;
    return plate.isEmpty ? descriptor : '$descriptor ($plate)';
  }
}
