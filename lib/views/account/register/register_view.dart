import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/services/app_links.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '注册账号',
      showBackButton: true,
      showBottomNavBar: false,
      backgroundColor: const Color(0xFFFBFCFE),
      body: GestureDetector(
        onTap: FocusScope.of(context).unfocus,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '注册账号',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                const Text(
                  '创建账号后即可管理车辆和设备',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 34),
                ReferenceInput(
                  controller: controller.phoneController,
                  hint: '请输入手机号',
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  prefix: const Icon(CupertinoIcons.phone),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => ReferenceInput(
                    controller: controller.codeController,
                    hint: '请输入6位短信验证码',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    prefix: const Icon(CupertinoIcons.chat_bubble),
                    suffix: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      onPressed: controller.canSendCode
                          ? controller.sendCode
                          : null,
                      child: Text(
                        controller.countdown.value > 0
                            ? '${controller.countdown.value}s后重试'
                            : '获取验证码',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => ReferenceInput(
                    controller: controller.passwordController,
                    hint: '请设置登录密码',
                    obscureText: controller.obscurePassword.value,
                    prefix: const Icon(CupertinoIcons.lock),
                    suffix: ReferenceIconButton(
                      onPressed: controller.obscurePassword.toggle,
                      icon: controller.obscurePassword.value
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 8),
                  child: Text(
                    '8–16 位，且必须包含数字、字母、特殊字符中的至少两种',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoCheckbox(
                        value: controller.agreed.value,
                        onChanged: (value) =>
                            controller.agreed.value = value ?? false,
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: Text.rich(
                            TextSpan(
                              text: '我已阅读并同意',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '《用户协议》',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = LegalLinks.openAgreement,
                                ),
                                const TextSpan(text: '和'),
                                TextSpan(
                                  text: '《隐私政策》',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = LegalLinks.openPrivacyPolicy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Obx(
                  () => ReferenceButton(
                    label: '注册并登录',
                    expand: true,
                    loading: controller.isSubmitting.value,
                    onPressed: controller.isSubmitReady
                        ? controller.submit
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  // 用 offAllNamed 清栈：offNamed 只是在栈顶再压一个登录页，
                  // 会与栈中已有的登录页形成「两个登录页」，其中旧的会因
                  // 重新绑定而拿到已销毁的输入控制器（输入无效 / 红屏）。
                  onPressed: () => Get.offAllNamed(Routes.login),
                  child: const Text('已有账号？去登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
