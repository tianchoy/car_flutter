import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class RegisterRepository {
  RegisterRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> sendSmsCode(String phone) =>
      _apiService.sendSmsCode(phoneNumber: phone, scene: 'register');

  Future<Response<dynamic>> register(Map<String, dynamic> data) =>
      _apiService.register(data);
}
