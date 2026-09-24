import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../services/post_consent_bootstrap.dart';
import '../../../services/privacy_consent_service.dart';
import '../../../services/startup_route_service.dart';
import '../../../widgets/app_toast.dart';

class PrivacyConsentController extends GetxController {
  final isSubmitting = false.obs;

  /// 同意：持久化同意状态，执行「同意后初始化」，再进入首页 / 登录页。
  Future<void> agree() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    await PrivacyConsentService.markConsented();
    // 等待 SDK 调用完成再跳转：首次安装时用户紧接着就要在登录页输入账号密码，
    // 若把 SDK 初始化留在事件循环里，会与其首次输入叠加造成卡顿。
    await PostConsentBootstrap.run(awaitSdkInitialization: true);
    final route = await StartupRouteService.resolve();
    isSubmitting.value = false;
    if (isClosed) return;
    Get.offAllNamed(route);
  }

  /// 不同意：不进入 App。
  ///
  /// Android 通过 [SystemNavigator.pop] 退出（等同于用户按返回键），
  /// iOS 不允许以代码方式结束应用，改为提示用户，由其自行退出。
  void decline() {
    if (GetPlatform.isAndroid) {
      SystemNavigator.pop();
      return;
    }
    AppToast.show('无法继续使用', '需同意《隐私政策》后才能使用本应用');
  }
}
