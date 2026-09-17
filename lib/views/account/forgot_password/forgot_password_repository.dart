import 'package:dio/dio.dart';

import 'package:car/shared/services/api_service.dart';

class ForgotPasswordRepository {
  ForgotPasswordRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> sendSmsCode(String phone) =>
      _apiService.sendSmsCode(phoneNumber: phone, scene: 'forgotPassword');

  Future<Response<dynamic>> resetPassword(Map<String, dynamic> data) =>
      _apiService.resetForgotPassword(data);
}
