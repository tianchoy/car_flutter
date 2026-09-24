import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

import '../../../services/app_links.dart';
import '../../../widgets/main_scaffold.dart';
import '../../../widgets/reference_ui.dart';
import 'privacy_consent_controller.dart';

/// 首次启动的《隐私政策》同意页。
///
/// 合规要求：必须在用户同意前显著提示，并确保同意之前不采集个人信息、
/// 不初始化采集类 SDK（相关初始化见 `PostConsentBootstrap`）。因此本页是
/// 未同意用户的唯一入口，提供「同意」与「不同意」两个明确选项。
class PrivacyConsentView extends GetView<PrivacyConsentController> {
  const PrivacyConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '隐私政策',
      showBackButton: false,
      showBottomNavBar: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Column(
                  children: [
                    Text(
                      '中导物联',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '车辆定位 · 轨迹回放 · 围栏告警',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ReferenceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '感谢您使用中导物联。为向您提供车辆定位、轨迹回放与地理围栏'
                      '告警服务，我们需要在您使用相应功能时收集必要的个人信息，'
                      '详情请查阅《隐私政策》。',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildLinks(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const ReferenceCard(
                child: Text(
                  '特别说明：为在 App 退到后台或锁屏时判断车辆是否驶入 / 驶出地理'
                  '围栏，我们需要在后台获取位置信息。您可随时在系统设置中关闭该'
                  '权限，关闭后围栏提醒将不可用，但不影响其他功能。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Obx(
                () => ReferenceButton(
                  label: '同意并继续',
                  expand: true,
                  loading: controller.isSubmitting.value,
                  onPressed: controller.agree,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => ReferenceButton(
                  label: '不同意',
                  expand: true,
                  filled: false,
                  loading: controller.isSubmitting.value,
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.decline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinks() {
    return Text.rich(
      TextSpan(
        text: '请阅读并同意',
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          color: AppColors.secondaryText,
        ),
        children: [
          TextSpan(
            text: '《用户协议》',
            style: const TextStyle(color: AppColors.primary),
            recognizer: TapGestureRecognizer()..onTap = LegalLinks.openAgreement,
          ),
          const TextSpan(text: '和'),
          TextSpan(
            text: '《隐私政策》',
            style: const TextStyle(color: AppColors.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = LegalLinks.openPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}
