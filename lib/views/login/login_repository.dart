import 'dart:convert';

import '../../models/api_response.dart';
import '../../services/api_service.dart';
import '../../utils/session.dart';

class LoginRepository {
  LoginRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<ApiResponse<JsonMap>> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw const ApiBusinessException(message: '用户名或密码不能为空');
    }

    final response = await _apiService.personalPasswordLogin(
      username: username.trim(),
      password: password,
    );
    final result = ApiResponse<JsonMap>.fromJson(
      response.data,
      dataParser: jsonMapFrom,
    );
    return _saveLoginResult(result);
  }

  Future<ApiResponse<JsonMap>> smsLogin(String phone, String code) async {
    if (phone.trim().isEmpty || code.trim().isEmpty) {
      throw const ApiBusinessException(message: '手机号或验证码不能为空');
    }

    final response = await _apiService.smsLogin(
      phoneNumber: phone.trim(),
      smsCode: code.trim(),
    );
    final result = ApiResponse<JsonMap>.fromJson(
      response.data,
      dataParser: jsonMapFrom,
    );
    return _saveLoginResult(result);
  }

  Future<void> sendSmsCode(String phone) async {
    final response = await _apiService.sendSmsCode(phoneNumber: phone.trim());
    final result = ApiResponse<Object?>.fromJson(response.data);
    if (!result.isSuccess) {
      throw ApiBusinessException(
        message: result.message.isEmpty ? '验证码发送失败' : result.message,
        code: result.code,
        payload: result.raw,
      );
    }
  }

  Future<ApiResponse<JsonMap>> _saveLoginResult(
    ApiResponse<JsonMap> result,
  ) async {
    if (!result.isSuccess) {
      throw ApiBusinessException(
        message: result.message.isEmpty ? '登录失败，请稍后重试' : result.message,
        code: result.code,
        payload: result.raw,
      );
    }

    final loginData = result.data ?? const <String, dynamic>{};
    final token = stringValue(loginData['access_token']).isNotEmpty
        ? stringValue(loginData['access_token'])
        : stringValue(loginData['token']);
    if (token.isEmpty) {
      throw const ApiBusinessException(message: '登录响应未包含访问凭证');
    }

    await setSession(SessionKeys.token, token);
    await _persistLoginMetadata(loginData);
    return result;
  }

  Future<void> _persistLoginMetadata(JsonMap loginData) async {
    final userType = stringValue(loginData['userType']).isNotEmpty
        ? stringValue(loginData['userType'])
        : stringValue(loginData['user_type']);
    if (userType.isNotEmpty) {
      await setSession(SessionKeys.userType, userType);
    }

    final profile = loginData['user'];
    if (profile is Map) {
      await setSession(
        SessionKeys.userProfile,
        jsonEncode(jsonMapFrom(profile)),
      );
    }
  }
}
