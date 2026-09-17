import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';

class ProfileRepository {
  ProfileRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// 获取当前登录用户个人信息（优先 GET /system/appUser/profile，
  /// 后端未部署时自动回退旧接口）。
  Future<Response<dynamic>> fetchProfile() => _apiService.getUserProfile();

  Future<Response<dynamic>> fetchDevices() =>
      _apiService.getUserDeviceList({'pageSize': 1000});

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // Clearing the local account is mandatory even when the server is offline.
    } finally {
      await clearAuthenticatedSession();
    }
  }

  Future<String?> getToken() => getSession(SessionKeys.token);
}
