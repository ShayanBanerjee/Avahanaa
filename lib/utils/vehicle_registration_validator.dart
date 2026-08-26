import '../l10n/l10n_global.dart';

class VehicleRegistrationValidator {
  const VehicleRegistrationValidator._();

  static final RegExp _separatorPattern = RegExp(r'[\s-]+');
  static final RegExp _standardPattern = RegExp(
    r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{1,4}$',
  );
  static final RegExp _bharatPattern = RegExp(
    r'^[0-9]{2}BH[0-9]{4}[A-Z]{1,2}$',
  );

  static String normalize(String value) {
    return value.trim().toUpperCase().replaceAll(_separatorPattern, '');
  }

  static bool isValid(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) {
      return false;
    }
    return _standardPattern.hasMatch(normalized) ||
        _bharatPattern.hasMatch(normalized);
  }

  static String? validationError(String? value) {
    final rawValue = value ?? '';
    if (normalize(rawValue).isEmpty) {
      return appL10n.valEnterRegistration;
    }
    if (!isValid(rawValue)) {
      return appL10n.valInvalidRegistration;
    }
    return null;
  }
}
