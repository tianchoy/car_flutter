import 'package:dio/dio.dart';

import 'package:car/shared/services/api_service.dart';

class ChangePasswordRepository {
  ChangePasswordRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> changePassword(Map<String, dynamic> data) =>
      _apiService.changePassword(data);
}
