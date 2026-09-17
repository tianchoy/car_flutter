import 'package:dio/dio.dart';

import '../../shared/services/api_service.dart';
import '../../utils/session.dart';

class ProfileRepository {
  ProfileRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Response<dynamic>> fetchProfile() => _apiService.getUserInfo();

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
