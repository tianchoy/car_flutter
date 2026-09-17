import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class VehicleListRepository {
  VehicleListRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchDevices({required int page}) =>
      _apiService.getUserDeviceList(<String, dynamic>{
        'page': page,
        'pageNum': page,
        'pageSize': 10,
      });
}
