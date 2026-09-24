import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

class ForgotPasswordRepository {
  ForgotPasswordRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // scene 取值与 Web 端一致（auth/request.uts 的 sendSmsForgotPasswordCode）。
  Future<Response<dynamic>> sendSmsCode(String phone) =>
      _apiService.sendSmsCode(phoneNumber: phone, scene: 'forgot');

  Future<Response<dynamic>> resetPassword(Map<String, dynamic> data) =>
      _apiService.resetForgotPassword(data);
}
