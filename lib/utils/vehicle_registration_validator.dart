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
      return 'Please enter your registration number';
    }
    if (!isValid(rawValue)) {
      return 'Please enter a valid registration number';
    }
    return null;
  }
}
