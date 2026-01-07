import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/vehicle_details.dart';

class VehicleRcService {
  VehicleRcService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _apiUrl =
      'https://rto-vehicle-details5.p.rapidapi.com/address';
  static const String _apiKey =
      '2af7283ee9msh6e36517829362abp1cd22djsn7feb3c87caf0';
  static const String _apiHost = 'rto-vehicle-details5.p.rapidapi.com';

  final Dio _dio;

  Future<Map<String, dynamic>> fetchVehicleDetails(String vehicleNumber) async {
    final normalizedNumber = vehicleNumber.trim().toUpperCase();
    if (normalizedNumber.isEmpty) {
      throw 'Vehicle number is required';
    }

    try {
      final response = await _dio.get(
        _apiUrl,
        queryParameters: {'registration': normalizedNumber},
        options: Options(
          headers: const {
            'x-rapidapi-key': _apiKey,
            'x-rapidapi-host': _apiHost,
          },
        ),
      );

      final data = _normalizeResponse(response.data);
      final errorMessage = _extractErrorMessage(data);
      if (errorMessage != null) {
        throw errorMessage;
      }
      if (data.isEmpty) {
        throw 'Vehicle details not found';
      }

      return data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final normalizedError = _normalizeResponse(errorData);
      final errorMessage = _extractErrorMessage(normalizedError);
      throw errorMessage ?? 'Failed to fetch vehicle details';
    }
  }

  Map<String, dynamic> buildCarDetails({
    required Map<String, dynamic> rcResponse,
    required String fallbackPlate,
  }) {
    final licensePlate = (rcResponse['asset_number'] ?? fallbackPlate)
        .toString()
        .trim();
    final carModel =
        (rcResponse['model_name2'] ??
                rcResponse['model_name'] ??
                rcResponse['make_model'] ??
                rcResponse['make_name'] ??
                rcResponse['make_name2'] ??
                '')
            .toString()
            .trim();
    final color =
        (rcResponse['color'] ?? rcResponse['colour'] ?? '').toString().trim();
    final vehicleDetails = VehicleDetails.fromRcResponse(rcResponse);
    final assetNumber = vehicleDetails.assetNumber.isNotEmpty
        ? vehicleDetails.assetNumber
        : licensePlate;

    return {
      'licensePlate': licensePlate,
      'carModel': carModel,
      'color': color,
      'assetNumber': assetNumber,
      if (vehicleDetails.variantId != null)
        'variantId': vehicleDetails.variantId,
      'rcResponse': rcResponse,
    };
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data == null) {
      return {};
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw 'Unexpected response format';
  }

  String? _extractErrorMessage(Map<String, dynamic> data) {
    final message = data['message']?.toString().trim();
    if (message != null && message.isNotEmpty && data.length == 1) {
      return message;
    }
    final error = data['error']?.toString().trim();
    if (error != null && error.isNotEmpty && data.length == 1) {
      return error;
    }
    return null;
  }
}
