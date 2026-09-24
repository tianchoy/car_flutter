import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'set_password_controller.dart';

/// 设置登录密码：登录返回 NEED_SET_PASSWORD 时进入，格式与注册页保持一致。
class SetPasswordView extends GetView<SetPasswordController> {
  const SetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '设置密码',
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
                  '设置登录密码',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                const Text(
                  '请设置登录密码后继续。',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 18),
                if (controller.phone.isNotEmpty)
                  Text(
                    '手机号：${controller.phone}',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                Obx(
                  () => ReferenceInput(
                    controller: controller.confirmController,
                    hint: '请再次输入登录密码',
                    obscureText: controller.obscureConfirm.value,
                    prefix: const Icon(CupertinoIcons.lock_rotation),
                    suffix: ReferenceIconButton(
                      onPressed: controller.obscureConfirm.toggle,
                      icon: controller.obscureConfirm.value
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: AppColors.secondaryText,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Obx(
                  () => ReferenceButton(
                    label: '完成设置',
                    expand: true,
                    loading: controller.isSubmitting.value,
                    onPressed: controller.isSubmitReady
                        ? controller.submit
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
