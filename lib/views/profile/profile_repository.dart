import '../../shared/services/api_service.dart';
import '../../utils/session.dart';
import '../../utils/Logger.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  // Future<Map<String, dynamic>> fetchProfile() async {
  //   return await _apiService.fetchProfile();
  // }
  Future<void> logout() async {
    await _apiService.logout();
    // 清除本地存储
    await deleteSession('token');
  }

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
