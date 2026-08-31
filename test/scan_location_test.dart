/// The scan location, which is the one piece of somebody else's data this app
/// touches — so the parsing is written to refuse rather than to guess.
library;

import 'package:avahanaa/models/scan_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsing', () {
    test('reads a well-formed fix', () {
      final location = ScanLocation.fromMap({
        'lat': 12.971,
        'lng': 77.594,
        'accuracyM': 240,
      });
      expect(location, isNotNull);
      expect(location!.latitude, 12.971);
      expect(location.longitude, 77.594);
      expect(location.accuracyMetres, 240);
    });

    test('refuses everything that is not a pair of coordinates', () {
      expect(ScanLocation.fromMap(null), isNull);
      expect(ScanLocation.fromMap('12.9,77.5'), isNull);
      expect(ScanLocation.fromMap(const {}), isNull);
      expect(ScanLocation.fromMap(const {'lat': 12.9}), isNull);
      expect(ScanLocation.fromMap(const {'lat': 'x', 'lng': 'y'}), isNull);
    });

    test('refuses out-of-range coordinates', () {
      expect(ScanLocation.fromMap(const {'lat': 91.0, 'lng': 0.5}), isNull);
      expect(ScanLocation.fromMap(const {'lat': 12.9, 'lng': 181.0}), isNull);
    });

    test('refuses null island', () {
      // (0, 0) is in the Atlantic. It is what a broken client sends and what a
      // real fix never is, and rendering it would send an owner a map pin off
      // the coast of Africa.
      expect(ScanLocation.fromMap(const {'lat': 0, 'lng': 0}), isNull);
    });

    test('accepts numeric strings, which is what some clients send', () {
      final location = ScanLocation.fromMap(const {
        'lat': '12.971',
        'lng': '77.594',
      });
      expect(location?.latitude, 12.971);
    });
  });

  group('accuracy', () {
    test('is floored at the grid the server rounds to', () {
      // The backend rounds coordinates to three decimals — about 110 m — so a
      // browser claiming 8 m is describing a precision that was thrown away
      // before storage. Reporting it would be a lie told by rounding.
      final location = ScanLocation.fromMap(const {
        'lat': 12.971,
        'lng': 77.594,
        'accuracyM': 8,
      });
      expect(location?.accuracyMetres, kScanLocationGridMetres.round());
    });

    test('a coarse fix keeps its own number', () {
      final location = ScanLocation.fromMap(const {
        'lat': 12.971,
        'lng': 77.594,
        'accuracyM': 2000,
      });
      expect(location?.accuracyMetres, 2000);
    });

    test('a missing or nonsense accuracy reads as unknown', () {
      expect(
        ScanLocation.fromMap(const {'lat': 12.9, 'lng': 77.5})?.accuracyMetres,
        isNull,
      );
      expect(
        ScanLocation.fromMap(const {
          'lat': 12.9,
          'lng': 77.5,
          'accuracyM': -1,
        })?.accuracyMetres,
        isNull,
      );
    });
  });

  group('map links', () {
    const location = ScanLocation(latitude: 12.971, longitude: 77.594);

    test('the geo URI carries a q= so a pin is actually dropped', () {
      // A bare `geo:lat,lng` centres the map and drops nothing, which is
      // indistinguishable from a map that failed to load.
      expect(location.geoUri, contains('q=12.971,77.594'));
    });

    test('the web fallback is a real search URL', () {
      expect(location.webMapUrl, startsWith('https://'));
      expect(location.webMapUrl, contains('12.971,77.594'));
    });
  });
}
