import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class DeviceListRepository {
  DeviceListRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchDevices({int pageSize = 1000}) =>
      _apiService.getUserDeviceList(<String, dynamic>{'pageSize': pageSize});

  Future<Response<dynamic>> deleteDevice(String deviceId) =>
      _apiService.deleteDevice(deviceId);
}
