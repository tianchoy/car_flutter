import 'package:dio/dio.dart';

import 'package:car/shared/services/api_service.dart';

class VehicleDetailRepository {
  VehicleDetailRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchDeviceInfo(String deviceId) =>
      _apiService.getDeviceInfo(deviceId);

  Future<Response<dynamic>> updateDevice(Map<String, dynamic> data) =>
      _apiService.updateDevice(data);
}
