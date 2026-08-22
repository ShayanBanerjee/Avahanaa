import 'package:avahanaa/utils/vehicle_registration_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleRegistrationValidator.normalize', () {
    test('uppercases and strips spaces and hyphens', () {
      expect(
        VehicleRegistrationValidator.normalize(' ka 01-ab 1234 '),
        'KA01AB1234',
      );
    });

    test('returns empty for blank input', () {
      expect(VehicleRegistrationValidator.normalize('   '), '');
    });
  });

  group('VehicleRegistrationValidator.isValid — standard series', () {
    test('accepts the common Karnataka format', () {
      expect(VehicleRegistrationValidator.isValid('KA01AB1234'), isTrue);
    });

    test('accepts spaced and hyphenated input', () {
      expect(VehicleRegistrationValidator.isValid('KA 01 AB 1234'), isTrue);
      expect(VehicleRegistrationValidator.isValid('KA-01-AB-1234'), isTrue);
    });

    test('accepts a single-digit district code', () {
      expect(VehicleRegistrationValidator.isValid('KA1AB1234'), isTrue);
    });

    test('accepts series with no letters', () {
      expect(VehicleRegistrationValidator.isValid('KA011234'), isTrue);
    });

    test('accepts a three-letter series', () {
      expect(VehicleRegistrationValidator.isValid('PB65AM0008'), isTrue);
      expect(VehicleRegistrationValidator.isValid('DL01CAA1234'), isTrue);
    });
  });

  group('VehicleRegistrationValidator.isValid — Bharat series', () {
    test('accepts the BH format', () {
      expect(VehicleRegistrationValidator.isValid('22BH1234AA'), isTrue);
      expect(VehicleRegistrationValidator.isValid('21BH0001A'), isTrue);
    });

    test('rejects a BH number with too many trailing letters', () {
      expect(VehicleRegistrationValidator.isValid('22BH1234ABC'), isFalse);
    });
  });

  group('VehicleRegistrationValidator.isValid — rejections', () {
    test('rejects empty input', () {
      expect(VehicleRegistrationValidator.isValid(''), isFalse);
      expect(VehicleRegistrationValidator.isValid('   '), isFalse);
    });

    test('rejects a state code that is not two letters', () {
      expect(VehicleRegistrationValidator.isValid('K01AB1234'), isFalse);
    });

    test('rejects a missing numeric tail', () {
      expect(VehicleRegistrationValidator.isValid('KA01AB'), isFalse);
    });

    test('rejects more than four trailing digits', () {
      expect(VehicleRegistrationValidator.isValid('KA01AB12345'), isFalse);
    });

    test('rejects punctuation that is not a separator', () {
      expect(VehicleRegistrationValidator.isValid('KA01/AB1234'), isFalse);
    });
  });

  group('VehicleRegistrationValidator.validationError', () {
    test('asks for a value when blank', () {
      expect(
        VehicleRegistrationValidator.validationError(''),
        'Please enter your registration number',
      );
      expect(
        VehicleRegistrationValidator.validationError(null),
        'Please enter your registration number',
      );
    });

    test('reports an invalid number', () {
      expect(
        VehicleRegistrationValidator.validationError('NOTAPLATE!'),
        'Please enter a valid registration number',
      );
    });

    test('returns null for a valid number', () {
      expect(VehicleRegistrationValidator.validationError('KA01AB1234'), isNull);
    });
  });
}
