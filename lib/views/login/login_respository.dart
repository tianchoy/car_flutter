import '../../shared/services/api_service.dart';
import '../../utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _apiService.login(username, password);

      // 解析响应数据
      Map<String, dynamic> responseData;

      if (response.data is String) {
        responseData = jsonDecode(response.data);
      } else if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response format');
      }
      Log.i('Login Response: $responseData');
      // 处理登录成功
      if (responseData['code'] == 200) {
        Log.i('Login Success: $responseData');
        if (responseData.containsKey('token')) {
          await prefs.setString('token', responseData['token']);
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map) {
          String? token = responseData['data']['token'];
          if (token != null) {
            await prefs.setString('token', token);
          }
        }

        return responseData;
      } else {
        String errorMsg = responseData['msg'] ?? '登录失败';
        Log.e('Login Failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      Log.e('Repository Error: $e');
      rethrow;
    }
  }
}
