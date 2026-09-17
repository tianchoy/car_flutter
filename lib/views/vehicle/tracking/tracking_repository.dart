import 'package:dio/dio.dart';

import 'package:car/shared/services/api_service.dart';

class TrackingRepository {
  TrackingRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchLastPosition(Map<String, dynamic> query) {
    return _apiService.getDeviceLastPosition(query);
  }
}
