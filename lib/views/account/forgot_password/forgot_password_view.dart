import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '找回密码',
      showBackButton: true,
      showBottomNavBar: false,
      backgroundColor: const Color(0xFFFBFCFE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Obx(
            () => controller.step.value == 3 ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSteps() {
    const titles = ['验证身份', '设置密码', '完成'];
    final current = controller.step.value;
    return Row(
      children: List.generate(titles.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Expanded(
            child: Container(
              height: 1,
              color: current > index ~/ 2 + 1
                  ? AppColors.primary
                  : AppColors.divider,
            ),
          );
        }
        final step = index ~/ 2 + 1;
        final active = step <= current;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : CupertinoColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                '$step',
                style: TextStyle(
                  color: active
                      ? CupertinoColors.white
                      : AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              titles[step - 1],
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildForm() {
    final firstStep = controller.step.value == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSteps(),
        const SizedBox(height: 62),
        if (firstStep) ...[
          ReferenceInput(
            controller: controller.phoneController,
            hint: '请输入绑定的手机号',
            keyboardType: TextInputType.phone,
            maxLength: 11,
            prefix: const Icon(CupertinoIcons.phone),
          ),
          const SizedBox(height: 12),
          ReferenceInput(
            controller: controller.codeController,
            hint: '请输入6位短信验证码',
            keyboardType: TextInputType.number,
            maxLength: 6,
            prefix: const Icon(CupertinoIcons.chat_bubble),
            suffix: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              onPressed:
                  controller.isSending.value || controller.countdown.value > 0
                  ? null
                  : controller.sendCode,
              child: Text(
                controller.countdown.value > 0
                    ? '${controller.countdown.value}s'
                    : '获取验证码',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Obx(
            () => ReferenceButton(
              label: '下一步',
              expand: true,
              onPressed: controller.isIdentityReady
                  ? controller.nextStep
                  : null,
            ),
          ),
        ] else ...[
          _passwordField(
            controller.passwordController,
            '请输入新密码',
            controller.obscurePassword.value,
            controller.obscurePassword.toggle,
            CupertinoIcons.lock,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 8),
            child: Text(
              '8–16 位，且必须包含数字、字母、特殊字符中的至少两种',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          _passwordField(
            controller.confirmController,
            '请再次输入新密码',
            controller.obscureConfirm.value,
            controller.obscureConfirm.toggle,
            CupertinoIcons.lock_fill,
          ),
          const SizedBox(height: 26),
          ReferenceButton(
            label: '确认重置',
            expand: true,
            loading: controller.isSubmitting.value,
            onPressed: controller.isResetReady
                ? controller.resetPassword
                : null,
          ),
        ],
      ],
    );
  }

  Widget _passwordField(
    TextEditingController fieldController,
    String hint,
    bool obscure,
    VoidCallback onToggle,
    IconData icon,
  ) {
    return ReferenceInput(
      controller: fieldController,
      hint: hint,
      obscureText: obscure,
      prefix: Icon(icon),
      suffix: ReferenceIconButton(
        onPressed: onToggle,
        icon: obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
        color: AppColors.secondaryText,
        size: 20,
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        _buildSteps(),
        const SizedBox(height: 110),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.check_mark,
            color: AppColors.success,
            size: 52,
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          '密码重置成功',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          '请使用新密码重新登录，原登录状态已失效。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.secondaryText, height: 1.5),
        ),
        const SizedBox(height: 70),
        ReferenceButton(
          label: '返回登录',
          expand: true,
          onPressed: () => Get.offAllNamed(Routes.login),
        ),
      ],
    );
  }
}
