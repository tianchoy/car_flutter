import 'package:dio/dio.dart';

import 'package:car/services/api_service.dart';

/// 设置登录密码（手机号已注册但尚未设置密码时补设）。
///
/// 与 Web 端 `pages/login/set-password` 一致：补设密码复用注册接口
///（`password` + `confirmPassword` + `phonenumber` + `smsCode`），
/// 成功后接口直接返回 `access_token`，可立即完成登录。
class SetPasswordRepository {
  SetPasswordRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> setPassword(Map<String, dynamic> data) =>
      _apiService.register(data);
}
