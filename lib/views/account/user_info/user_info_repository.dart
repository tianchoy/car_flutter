import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class UserInfoRepository {
  UserInfoRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchUserInfo() => _apiService.getUserInfo();
}
