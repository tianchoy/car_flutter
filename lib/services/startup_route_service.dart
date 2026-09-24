import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../utils/session.dart';
import 'privacy_consent_service.dart';

class StartupRouteService {
  StartupRouteService._();

  /// 启动落点。
  ///
  /// 未同意《隐私政策》时先进同意页——这是合规门槛，必须早于一切 SDK 初始化
  /// （相关初始化见 `PostConsentBootstrap`）。已同意时再按登录态分流。
  static Future<String> resolve() async {
    if (!await PrivacyConsentService.hasConsented()) {
      return Routes.privacyConsent;
    }
    return await hasAuthenticatedSession() ? Routes.home : Routes.login;
  }
}

class StartupController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _redirect();
  }

  Future<void> _redirect() async {
    final route = await StartupRouteService.resolve();
    if (!isClosed && Get.currentRoute == Routes.startup) {
      Get.offAllNamed(route);
    }
  }
}
