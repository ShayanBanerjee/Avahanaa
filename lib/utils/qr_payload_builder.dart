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

  /// The host the stickers point at, for anything else that has to talk to the
  /// same deployment.
  ///
  /// Exposed because the app's own API client ([AvahanaaApi]) must reach the
  /// backend that serves these QR URLs, and a second `--dart-define` for the
  /// same value is a staging build waiting to point half of itself at
  /// production.
  static String get redirectHost => _qrHost;

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
      // Firestore has no case-insensitive equality, so the plate is stored a
      // second time in a normalised form for the backend's plate lookup to
      // match on. `KA 01 AB 1234`, `ka-01-ab-1234` and `KA01AB1234` all have
      // to resolve to the same vehicle — the person typing it is standing in
      // the street reading it off a bumper.
      //
      // Display still uses `licensePlate`; this field is only ever a key.
      if (vehiclePlate.isNotEmpty)
        'licensePlateCanonical': canonicalisePlate(vehiclePlate),
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

  /// Uppercases and strips everything that is not a letter or digit.
  ///
  /// Must stay byte-identical to `canonicalisePlate` in the backend's
  /// `functions/index.js` — the two are the read and write halves of the same
  /// index, and a mismatch shows up as "no vehicle matches that number" rather
  /// than as an error.
  static String canonicalisePlate(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
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
