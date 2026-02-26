import '../models/user_model.dart';
import '../models/vehicle_model.dart';

class QrPayloadBuilder {
  const QrPayloadBuilder._();

  static const String _defaultHost = 'avahanaa.com';
  static const String _defaultPath = 'index.html';
  static const String _defaultShortRoutePrefix = 'n';
  static const String _payloadVersion = '3';

  static final String _qrHost = const String.fromEnvironment(
    'QR_REDIRECT_HOST',
    defaultValue: _defaultHost,
  );
  static final String _qrPath = const String.fromEnvironment(
    'QR_REDIRECT_PATH',
    defaultValue: _defaultPath,
  );
  static final String _qrShortRoutePrefix = const String.fromEnvironment(
    'QR_SHORT_ROUTE_PREFIX',
    defaultValue: _defaultShortRoutePrefix,
  );
  static final bool _useShortRoute = const bool.fromEnvironment(
    'QR_USE_SHORT_ROUTE',
    defaultValue: true,
  );

  static Map<String, dynamic> buildMetadata({
    required UserModel user,
    required VehicleModel vehicle,
  }) {
    final vehicleColor = _toTrimmedString(vehicle.color);
    final vehicleModel = _toTrimmedString(vehicle.carModel);
    final vehiclePlate = _toTrimmedString(vehicle.licensePlate);
    final vehicleMetadata = <String, String>{
      if (vehicleColor.isNotEmpty) 'color': vehicleColor,
      if (vehicleModel.isNotEmpty) 'carModel': vehicleModel,
      if (vehiclePlate.isNotEmpty) 'licensePlate': vehiclePlate,
    };

    return {
      'payloadVersion': _payloadVersion,
      if (vehicleMetadata.isNotEmpty) 'vehicle': vehicleMetadata,
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
    final qrCodeId = _toTrimmedString(vehicle.qrCodeId);
    final shortRoutePrefix = _normalisePath(_qrShortRoutePrefix);

    if (_useShortRoute && qrCodeId.isNotEmpty && shortRoutePrefix.isNotEmpty) {
      return Uri.https(_qrHost, '$shortRoutePrefix/$qrCodeId');
    }

    final queryParameters = <String, String>{
      // Keep the redirect page hint but otherwise minimise the query to shrink the QR payload.
      'page': 'notify',
    };

    if (qrCodeId.isNotEmpty) {
      queryParameters['qr'] = qrCodeId;
    }

    // Carry a lightweight version flag for future compatibility without the heavy encrypted payload.
    queryParameters['v'] = _payloadVersion;

    final redirectPath = _normalisePath(_qrPath).isEmpty
        ? _defaultPath
        : _normalisePath(_qrPath);

    return Uri.https(_qrHost, redirectPath, queryParameters);
  }

  static String _toTrimmedString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static String _normalisePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'/+$'), '');
  }
}
