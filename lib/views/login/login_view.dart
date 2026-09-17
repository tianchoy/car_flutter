import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../services/app_links.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/reference_ui.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '登录',
      showBackButton: false,
      showBottomNavBar: false,
      backgroundColor: const Color(0xFFFBFCFE),
      body: GestureDetector(
        onTap: FocusScope.of(context).unfocus,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrand(),
                const SizedBox(height: 26),
                _buildModeSwitch(),
                const SizedBox(height: 18),
                Obx(
                  () => controller.useSmsLogin.value
                      ? _buildSmsForm()
                      : _buildPasswordForm(),
                ),
                const SizedBox(height: 12),
                _buildAgreement(context),
                const SizedBox(height: 18),
                _buildLoginButton(context),
                const SizedBox(height: 18),
                _buildLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.location_solid,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          '中导物联',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '智能车联网管理平台',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildModeSwitch() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.useSmsLogin.value = false,
              child: _modeTab('密码登录', !controller.useSmsLogin.value),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.useSmsLogin.value = true,
              child: _modeTab('验证码登录', controller.useSmsLogin.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.secondaryText,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      children: [
        ReferenceInput(
          controller: controller.usernameController,
          hint: '请输入账号或手机号',
          prefix: const Icon(CupertinoIcons.person),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 13),
        Obx(
          () => ReferenceInput(
            controller: controller.passwordController,
            hint: '请输入密码',
            obscureText: controller.obscurePassword.value,
            onSubmitted: (_) => controller.login(),
            prefix: const Icon(CupertinoIcons.lock),
            suffix: ReferenceIconButton(
              icon: controller.obscurePassword.value
                  ? CupertinoIcons.eye_slash
                  : CupertinoIcons.eye,
              onPressed: controller.togglePasswordVisibility,
              color: AppColors.secondaryText,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsForm() {
    return Column(
      children: [
        ReferenceInput(
          controller: controller.phoneController,
          hint: '请输入手机号',
          keyboardType: TextInputType.phone,
          prefix: const Icon(CupertinoIcons.phone),
        ),
        const SizedBox(height: 13),
        Obx(
          () => ReferenceInput(
            controller: controller.smsCodeController,
            hint: '请输入验证码',
            keyboardType: TextInputType.number,
            prefix: const Icon(CupertinoIcons.chat_bubble),
            suffix: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              onPressed: controller.canSendSmsCode
                  ? controller.sendSmsCode
                  : null,
              child: Text(
                controller.smsCountdown.value == 0
                    ? '获取验证码'
                    : '${controller.smsCountdown.value}s',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreement(BuildContext context) {
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Transform.scale(
              scale: 1.15,
              child: CupertinoCheckbox(
                value: controller.agreed.value,
                onChanged: (value) => controller.agreed.value = value ?? false,
                activeColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '我已阅读并同意',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '《用户协议》',
                    style: const TextStyle(color: AppColors.primary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => LegalLinks.showUserAgreement(context),
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: const TextStyle(color: AppColors.primary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => LegalLinks.showPrivacyPolicy(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Obx(
      () => ReferenceButton(
        label: '登录',
        expand: true,
        loading: controller.isLoading.value,
        onPressed: controller.isFormValid && controller.agreed.value
            ? () {
                FocusScope.of(context).unfocus();
                controller.login();
              }
            : null,
      ),
    );
  }

  Widget _buildLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.toNamed(Routes.register),
          child: const Text('注册账号›'),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.toNamed(Routes.forgotPassword),
          child: const Text('忘记密码›'),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.offAllNamed(Routes.home),
          child: const Text('暂不登录›'),
        ),
      ],
    );
  }
}
