import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '修改密码',
      showBackButton: true,
      showBottomNavBar: false,
      backgroundColor: const Color(0xFFFBFCFE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '修改密码',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 9),
              const Text(
                '修改后，当前及其他设备均需重新登录。',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 38),
              Obx(
                () => _passwordField(
                  controller.oldController,
                  '请输入当前密码',
                  controller.oldObscure.value,
                  controller.oldObscure.toggle,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => _passwordField(
                  controller.newController,
                  '请输入新密码',
                  controller.newObscure.value,
                  controller.newObscure.toggle,
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
              const SizedBox(height: 12),
              Obx(
                () => _passwordField(
                  controller.confirmController,
                  '请再次输入新密码',
                  controller.confirmObscure.value,
                  controller.confirmObscure.toggle,
                ),
              ),
              const SizedBox(height: 28),
              Obx(
                () => ReferenceButton(
                  label: '确认修改',
                  expand: true,
                  loading: controller.isSubmitting.value,
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submit,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => Get.toNamed(Routes.forgotPassword),
                child: const Text('忘记当前密码？'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController fieldController,
    String hint,
    bool obscure,
    VoidCallback onToggle,
  ) {
    return ReferenceInput(
      controller: fieldController,
      hint: hint,
      obscureText: obscure,
      prefix: const Icon(CupertinoIcons.lock),
      suffix: ReferenceIconButton(
        onPressed: onToggle,
        icon: obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
        color: AppColors.secondaryText,
        size: 20,
      ),
    );
  }
}
