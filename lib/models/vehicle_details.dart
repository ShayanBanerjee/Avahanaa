class VehicleDetails {
  final String assetNumber;
  final int? variantId;

  const VehicleDetails({
    required this.assetNumber,
    this.variantId,
  });

  factory VehicleDetails.fromRcResponse(Map<String, dynamic> rcResponse) {
    final assetNumber = _readString(rcResponse['asset_number']);
    final variantId = _extractVariantId(rcResponse['variant_id']);

    return VehicleDetails(
      assetNumber: assetNumber,
      variantId: variantId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assetNumber': assetNumber,
      'variantId': variantId,
    };
  }

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static int? _extractVariantId(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is List) {
      if (raw.isEmpty) {
        return null;
      }
      return _extractVariantId(raw.first);
    }
    if (raw is num) {
      return raw.toInt();
    }
    final value = raw.toString().trim();
    if (value.isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }
}
