import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class AddDeviceRepository {
  AddDeviceRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> addDevice(Map<String, dynamic> data) =>
      _apiService.addDevice(data);
}
