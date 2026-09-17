import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class RenewalRepository {
  RenewalRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchDevices() => _apiService.getUserDeviceList(
    <String, dynamic>{'page': 1, 'pageNum': 1, 'pageSize': 100},
  );
}
