import '../models/user_model.dart';
import '../models/vehicle_model.dart';

class QrPayloadBuilder {
  const QrPayloadBuilder._();

  static const String _defaultHost = 'avahanaa.com';
  static const String _defaultPath = 'index.html';
  static const String _payloadVersion = '3';

  static final String _qrHost = const String.fromEnvironment(
    'QR_REDIRECT_HOST',
    defaultValue: _defaultHost,
  );
  static final String _qrPath = const String.fromEnvironment(
    'QR_REDIRECT_PATH',
    defaultValue: _defaultPath,
  );

  static Map<String, dynamic> buildMetadata({
    required UserModel user,
    required VehicleModel vehicle,
  }) {
    return {
      'payloadVersion': _payloadVersion,
      'qrCodeId': _toTrimmedString(vehicle.qrCodeId),
      'userId': _toTrimmedString(user.id),
      'vehicleId': _toTrimmedString(vehicle.id),
      'fcmToken': _toTrimmedString(user.fcmToken),
      'contact': {
        'email': _toTrimmedString(user.email),
        'phoneNumber': _toTrimmedString(user.phoneNumber),
      },
      'vehicle': {
        'color': _toTrimmedString(vehicle.color),
        'carModel': _toTrimmedString(vehicle.carModel),
        'licensePlate': _toTrimmedString(vehicle.licensePlate),
      },
    };
  }

  static String buildPayload({
    required UserModel user,
    required VehicleModel vehicle,
  }) {
    return _buildQrUri(user: user, vehicle: vehicle).toString();
  }

  static String buildShareableLink({
    required UserModel user,
    required VehicleModel vehicle,
  }) {
    return buildPayload(user: user, vehicle: vehicle);
  }

  static Uri _buildQrUri({
    required UserModel user,
    required VehicleModel vehicle,
  }) {
    final queryParameters = <String, String>{
      // Keep the redirect page hint but otherwise minimise the query to shrink the QR payload.
      'page': 'notify',
    };

    final qrCodeId = _toTrimmedString(vehicle.qrCodeId);
    if (qrCodeId.isNotEmpty) {
      queryParameters['qr'] = qrCodeId;
    }

    // Carry a lightweight version flag for future compatibility without the heavy encrypted payload.
    queryParameters['v'] = _payloadVersion;

    return Uri.https(
      _qrHost,
      _qrPath,
      queryParameters.isEmpty ? null : queryParameters,
    );
  }

  static String _toTrimmedString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }
}
