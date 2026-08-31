/// Where the vehicle was when somebody scanned it.
///
/// The owner's first question on getting an alert is "which car, and where?" —
/// they may have three vehicles and no idea which windscreen was scanned. One
/// coordinate answers it.
///
/// ## What this deliberately is not
///
/// It is **not** a precise fix, and it is not the scanner's location in any
/// useful sense. The backend rounds to three decimal places — about 110 m at
/// Bangalore's latitude — before it is stored, and the raw reading is never
/// written down. That is enough to find a parked car and not enough to follow
/// a person.
///
/// The asymmetry matters. This product's whole premise is that the person who
/// scans a sticker gives up nothing: no name, no number, no way to be contacted
/// back. Attaching their exact coordinates to the alert would quietly reverse
/// that, and the moment word got out, nobody would press the button. The
/// coarsening is not a nicety; it is the same promise pointed the other way.
///
/// It is also optional on every path. The browser asks, and a great many people
/// will say no or never see the prompt. An alert without a location is an
/// ordinary alert.
library;

/// Metres, roughly, that three decimal places of latitude covers.
///
/// Used to floor the displayed accuracy: reporting "accurate to 8 m" on a
/// coordinate that was deliberately rounded to 110 m would be a lie told by
/// rounding, and the owner would trust the pin more than it deserves.
const double kScanLocationGridMetres = 110;

class ScanLocation {
  const ScanLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMetres,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;

  /// The radius the browser claimed, in metres, or null when it said nothing.
  ///
  /// Worth keeping and worth showing. A 20 m fix and a 2 km one mean very
  /// different things to somebody deciding whether to put shoes on, and an app
  /// that renders both as an identical pin is lying about one of them.
  final int? accuracyMetres;

  final DateTime? capturedAt;

  /// Parses the `location` map on a notification document.
  ///
  /// Returns null for anything that is not a usable pair of coordinates —
  /// absent, malformed, out of range, or the (0, 0) in the Atlantic that a
  /// broken client sends and a real fix never does.
  static ScanLocation? fromMap(Object? raw) {
    if (raw is! Map) return null;

    final lat = _asDouble(raw['lat']);
    final lng = _asDouble(raw['lng']);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    if (lat == 0 && lng == 0) return null;

    final accuracy = _asDouble(raw['accuracyM']);
    final capturedAt = raw['capturedAt'];

    return ScanLocation(
      latitude: lat,
      longitude: lng,
      accuracyMetres: accuracy == null || accuracy <= 0
          ? null
          // Floored at the grid size. See [kScanLocationGridMetres].
          : (accuracy < kScanLocationGridMetres
                    ? kScanLocationGridMetres
                    : accuracy)
                .round(),
      capturedAt: capturedAt is DateTime
          ? capturedAt
          // A Firestore Timestamp, without importing cloud_firestore into a
          // model that is otherwise plain — `toDate` is the whole interface.
          : (capturedAt != null && capturedAt is! String
                ? _tryToDate(capturedAt)
                : null),
    );
  }

  static DateTime? _tryToDate(Object value) {
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// A `geo:` URI, which every Android map app handles.
  ///
  /// The `q=` parameter is what makes the pin appear — a bare `geo:lat,lng`
  /// centres the map there and drops nothing, which looks identical to a map
  /// that failed to load.
  String get geoUri => 'geo:$latitude,$longitude?q=$latitude,$longitude';

  /// The universal web fallback, for a device with no map app registered.
  String get webMapUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  Map<String, dynamic> toMap() => {
    'lat': latitude,
    'lng': longitude,
    if (accuracyMetres != null) 'accuracyM': accuracyMetres,
  };

  @override
  bool operator ==(Object other) =>
      other is ScanLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyMetres == accuracyMetres;

  @override
  int get hashCode => Object.hash(latitude, longitude, accuracyMetres);

  @override
  String toString() =>
      'ScanLocation($latitude, $longitude, ±${accuracyMetres ?? "?"}m)';
}
