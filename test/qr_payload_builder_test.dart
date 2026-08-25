import 'package:avahanaa/models/user_model.dart';
import 'package:avahanaa/models/vehicle_model.dart';
import 'package:avahanaa/utils/qr_payload_builder.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user() => UserModel(id: 'user-1', email: 'owner@example.com');

VehicleModel _vehicle({
  String qrCodeId = 'qr-abc123',
  String color = 'White',
  String carModel = 'Maruti Swift',
  String licensePlate = 'KA01AB1234',
}) {
  return VehicleModel(
    id: 'vehicle-1',
    userId: 'user-1',
    color: color,
    carModel: carModel,
    licensePlate: licensePlate,
    qrCodeId: qrCodeId,
  );
}

void main() {
  group('QrPayloadBuilder.buildPayload', () {
    test('builds the short scan route for a vehicle with a QR id', () {
      final payload = QrPayloadBuilder.buildPayload(
        user: _user(),
        vehicle: _vehicle(),
      );

      expect(payload, 'https://avahanaa.com/n/qr-abc123');
    });

    test('falls back to the query route when the QR id is missing', () {
      final payload = QrPayloadBuilder.buildPayload(
        user: _user(),
        vehicle: _vehicle(qrCodeId: ''),
      );

      final uri = Uri.parse(payload);
      expect(uri.host, 'avahanaa.com');
      expect(uri.path, '/index.html');
      expect(uri.queryParameters['page'], 'notify');
      expect(uri.queryParameters['v'], '3');
      expect(uri.queryParameters.containsKey('qr'), isFalse);
    });

    test('always uses https', () {
      final payload = QrPayloadBuilder.buildPayload(
        user: _user(),
        vehicle: _vehicle(),
      );

      expect(Uri.parse(payload).scheme, 'https');
    });

    test('leaks no owner identifiers into the payload', () {
      // The entire product promise: a scanner learns nothing about the owner.
      final payload = QrPayloadBuilder.buildPayload(
        user: _user(),
        vehicle: _vehicle(),
      );

      expect(payload, isNot(contains('owner@example.com')));
      expect(payload, isNot(contains('user-1')));
    });

    test('buildShareableLink matches buildPayload', () {
      final user = _user();
      final vehicle = _vehicle();

      expect(
        QrPayloadBuilder.buildShareableLink(user: user, vehicle: vehicle),
        QrPayloadBuilder.buildPayload(user: user, vehicle: vehicle),
      );
    });
  });

  group('QrPayloadBuilder.buildMetadata', () {
    test('carries only vehicle description fields', () {
      final metadata = QrPayloadBuilder.buildMetadata(
        user: _user(),
        vehicle: _vehicle(),
      );

      expect(metadata['payloadVersion'], '3');
      expect(metadata['vehicle'], {
        'color': 'White',
        'carModel': 'Maruti Swift',
        'licensePlate': 'KA01AB1234',
        'licensePlateCanonical': 'KA01AB1234',
      });
    });

    test('stores a normalised plate for the backend to match on', () {
      // Firestore has no case-insensitive equality, so the plate lookup at
      // /api/lookup matches on this field rather than on the display one.
      // Someone typing a registration off a bumper will not reproduce the
      // owner's spacing.
      final metadata = QrPayloadBuilder.buildMetadata(
        user: _user(),
        vehicle: _vehicle(licensePlate: 'ka-01 ab 1234'),
      );
      final vehicle = metadata['vehicle'] as Map<String, dynamic>;

      expect(vehicle['licensePlate'], 'ka-01 ab 1234');
      expect(vehicle['licensePlateCanonical'], 'KA01AB1234');
    });

    test('canonicalisation agrees with the backend implementation', () {
      // The read half of this index is `canonicalisePlate` in the backend's
      // functions/index.js:
      //     value.toUpperCase().replace(/[^A-Z0-9]/g, "")
      // If these two ever diverge, plate lookup fails as "no vehicle matches
      // that number" rather than as an error, so it is pinned here.
      expect(QrPayloadBuilder.canonicalisePlate('KA 01 AB 1234'), 'KA01AB1234');
      expect(QrPayloadBuilder.canonicalisePlate('ka-01-ab-1234'), 'KA01AB1234');
      expect(QrPayloadBuilder.canonicalisePlate('  ka01ab1234  '), 'KA01AB1234');
      expect(QrPayloadBuilder.canonicalisePlate(''), '');
    });

    test('never includes owner contact details', () {
      final metadata = QrPayloadBuilder.buildMetadata(
        user: _user(),
        vehicle: _vehicle(),
      );

      expect(metadata.toString(), isNot(contains('owner@example.com')));
      expect(metadata.containsKey('email'), isFalse);
      expect(metadata.containsKey('phoneNumber'), isFalse);
      expect(metadata.containsKey('userId'), isFalse);
    });

    test('omits the vehicle block entirely when nothing is set', () {
      final metadata = QrPayloadBuilder.buildMetadata(
        user: _user(),
        vehicle: _vehicle(color: '', carModel: '', licensePlate: ''),
      );

      expect(metadata.containsKey('vehicle'), isFalse);
      expect(metadata['payloadVersion'], '3');
    });

    test('trims whitespace from vehicle fields', () {
      final metadata = QrPayloadBuilder.buildMetadata(
        user: _user(),
        vehicle: _vehicle(color: '  Red  ', carModel: '  Honda City '),
      );

      final vehicle = metadata['vehicle'] as Map<String, String>;
      expect(vehicle['color'], 'Red');
      expect(vehicle['carModel'], 'Honda City');
    });
  });
}
