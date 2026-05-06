// login_respository.dart
import '../../shared/services/api_service.dart';
import '../../utils/Logger.dart';
import '../../utils/session.dart';
import 'dart:convert';

class LoginRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    // 参数验证
    if (username.isEmpty || password.isEmpty) {
      throw Exception('用户名或密码不能为空');
    }

    try {
      final response = await _apiService.login(username, password);

      // 解析响应数据
      Map<String, dynamic> responseData;
      if (response.data is Map) {
        // 如果已经是 Map，直接使用
        responseData = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        // 如果是字符串，解析JSON
        responseData = jsonDecode(response.data);
      } else {
        throw Exception('响应格式错误');
      }

      Log.i('Login Response: $responseData');
      if (responseData['code'] == 0) {
        Log.i('Login Success: $responseData');
        String? token;
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          token = responseData['data']['token'];
        } else if (responseData.containsKey('token')) {
          token = responseData['token'];
        }

        if (token != null && token.isNotEmpty) {
          await setSession('token', token);
        } else {
          Log.w('Warning: No token found in response');
        }

        return responseData;
      } else {
        String errorMsg = responseData['msg'] ?? '登录失败';
        Log.e('Login Failed: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      Log.e('Repository Error: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('网络连接失败，请检查网络设置');
      } else if (e.toString().contains('Timeout')) {
        throw Exception('请求超时，请稍后重试');
      }
      rethrow;
    }
  }
}
