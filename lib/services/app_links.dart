import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../app/routes/route_arguments.dart';
import '../../app/routes/router_instance.dart';
import '../widgets/reference_ui.dart';

/// Destinations used by links that are shared across account screens.
class LegalLinks {
  LegalLinks._();

  static const userAgreementUrl = 'https://gpsapp.zdiot.cn/user-agreement';
  static const privacyPolicyUrl = 'https://gpsapp.zdiot.cn/privacy-policy';
  static const customerServiceHours = '每日 08:00–24:00';
  static const customerServiceDescription = '如需帮助，请联系在线客服。';

  static const userAgreement = '''欢迎使用车联网平台！

一、服务条款的确认和接纳
本协议是您与车联网平台之间关于使用平台服务的协议。您使用平台服务即表示您已阅读并同意本协议的全部条款。

二、服务内容
1. 车联网平台提供车辆管理、远程控制、数据分析等服务。
2. 平台保留随时变更、中断或终止部分或全部网络服务的权利。

三、用户账号
用户应对其账号的全部行为负责，不得将账号转让或出借给他人使用。

四、用户隐私保护
保护用户隐私是平台的一项基本政策，详情请参阅《隐私政策》。

五、免责声明
1. 平台不保证服务一定能满足用户的要求，也不保证服务不会中断。
2. 对于因不可抗力造成的服务中断，平台不承担责任。

六、法律适用
本协议的订立、执行和解释及争议的解决均适用中华人民共和国法律。

如有任何疑问，请联系我们。''';

  static const privacyPolicy = '''车联网平台非常重视您的隐私保护！

一、信息收集
1. 我们可能收集的信息包括：手机号码、车辆信息、位置信息、设备信息等。
2. 我们会在您注册、使用服务时收集必要的信息。

二、信息使用
1. 我们使用收集的信息来提供、维护和改进服务。
2. 我们不会向第三方出售或分享您的个人信息。

三、信息保护
1. 我们采用行业标准的安全措施保护您的信息。
2. 我们会定期评估安全措施的有效性。

四、未成年人保护
我们重视未成年人的隐私保护，如您是未成年人，请在监护人指导下使用服务。

五、政策更新
我们可能会更新隐私政策，更新后的政策将在平台公布。

如有任何隐私问题，请联系我们。''';

  static void openAgreement() => _open('用户协议', userAgreementUrl);
  static void openPrivacyPolicy() => _open('隐私政策', privacyPolicyUrl);

  static Future<void> showUserAgreement(BuildContext context) =>
      _showDocument(context, title: '用户协议', content: userAgreement);

  static Future<void> showPrivacyPolicy(BuildContext context) =>
      _showDocument(context, title: '隐私政策', content: privacyPolicy);

  static void _open(String title, String url) {
    Get.toNamed(
      Routes.webContent,
      arguments: WebContentRouteArgs(title: title, url: url),
    );
  }

  static Future<void> _showDocument(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: SizedBox(
          height: MediaQuery.sizeOf(dialogContext).height * .55,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
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
