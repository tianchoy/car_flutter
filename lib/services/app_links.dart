import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../app/routes/route_arguments.dart';
import '../../app/routes/router_instance.dart';

/// Destinations used by links that are shared across account screens.
///
/// 用户协议与隐私政策以**本地 HTML 资源**形式随包分发，不走服务端路由：
/// 一是应用市场审核会实际点开协议链接，链接失效会直接导致驳回；二是离线
/// 状态下也能正常查看。资源文件位于 `assets/legal/`，在 `pubspec.yaml`
/// 的 `flutter.assets` 中声明。
class LegalLinks {
  LegalLinks._();

  static const userAgreementAsset = 'assets/legal/user_agreement.html';
  static const privacyPolicyAsset = 'assets/legal/privacy_policy.html';

  static const userAgreementTitle = '用户协议';
  static const privacyPolicyTitle = '隐私政策';

  static const customerServiceHours = '每日 08:00–24:00';
  static const customerServiceDescription = '如需帮助，请联系在线客服。';

  static void openAgreement() => _open(userAgreementTitle, userAgreementAsset);

  static void openPrivacyPolicy() =>
      _open(privacyPolicyTitle, privacyPolicyAsset);

  static void _open(String title, String assetPath) {
    Get.toNamed(
      Routes.webContent,
      arguments: WebContentRouteArgs(title: title, assetPath: assetPath),
    );
  }

  static Future<void> showCustomerService(BuildContext context) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('联系客服'),
        // 标题与内容之间留出间距，避免两者贴得太近。
        content: const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customerServiceDescription),
              SizedBox(height: 10),
              Text(customerServiceHours),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
