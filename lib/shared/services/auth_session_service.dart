import 'package:get/get.dart';

import '../../app/router_instance.dart';
import '../../utils/session.dart';
import 'api_service.dart';

/// Owns the irreversible local part of logout.
///
/// Network logout is best-effort so an unavailable server can never leave an
/// access token or account-scoped data on the device.
class AuthSessionService {
  AuthSessionService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // Local credentials must still be cleared when the backend is unavailable.
    } finally {
      await clearAuthenticatedSession();
    }
  }

  Future<void> logoutAndRedirect() async {
    await logout();
    Get.offAllNamed(Routes.login);
  }
}
