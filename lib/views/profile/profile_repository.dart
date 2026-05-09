import 'package:dio/src/response.dart';

import '../../shared/services/api_service.dart';
import '../../utils/Logger.dart';
import '../../utils/session.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  // 获取用户信息API
  Future<Response<dynamic>> fetchProfile() async {
    return await _apiService.getUserInfo();
  }

  // 退出登录API
  Future<void> logout() async {
    await _apiService.logout();
    // 清除本地存储
    await deleteSession('token');
  }

  // 检查 token 是否有效
  Future<bool> checkToken() async {
    try {
      final token = await getSession('token');
      Log.i('检查 token: $token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      Log.e('检查 token 失败', error: e);
      return false;
    }
  }
}
