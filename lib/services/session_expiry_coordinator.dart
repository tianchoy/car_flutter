import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import '../../app/routes/router_instance.dart';
import '../../utils/session.dart';

/// Coordinates one logout transition for concurrent expired requests.
class SessionExpiryCoordinator {
  SessionExpiryCoordinator._();

  static Future<void>? _activeRequest;

  static Future<void> handleExpiredSession({String message = '登录已过期，请重新登录'}) {
    final activeRequest = _activeRequest;
    if (activeRequest != null) return activeRequest;

    final request = _clearAndRedirect(message);
    _activeRequest = request.whenComplete(() => _activeRequest = null);
    return _activeRequest!;
  }

  static Future<void> _clearAndRedirect(String message) async {
    await clearAuthenticatedSession();

    if (Get.context != null) {
      AppToast.show('提示', message, duration: const Duration(seconds: 2));
    }

    if (Get.currentRoute != Routes.login) {
      Get.offAllNamed(Routes.login);
    }
  }
}
