import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../utils/session.dart';
import 'api_service.dart';
import 'push/push_binding_service.dart';
import 'push/push_service.dart';
import 'unread_count_service.dart';

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
      // 先解绑推送设备：解绑需要业务 token，必须在本地会话清理之前发出。
      await PushBindingService.to.unbindOnLogout();
      await _apiService.logout();
    } catch (_) {
      // Local credentials must still be cleared when the backend is unavailable.
    } finally {
      await PushService.to.clearSessionState();
      await clearAuthenticatedSession();
      // 退出登录后「消息」角标必须立即消失，避免下一个账号登录前展示上一个账号的未读数。
      UnreadCountService.to.clear();
    }
  }

  Future<void> logoutAndRedirect() async {
    await logout();
    Get.offAllNamed(Routes.login);
  }
}
