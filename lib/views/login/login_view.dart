import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录'), centerTitle: true, elevation: 2),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 30),
                _buildLoginButton(),
                const SizedBox(height: 16),
                _buildFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Icon(Icons.lock_outline, size: 80, color: Get.theme.primaryColor),
        const SizedBox(height: 16),
        Text(
          '欢迎回来',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请登录以继续',
          style: Get.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Obx(
      () => CupertinoTextField(
        controller: controller.usernameController,
        placeholder: '请输入用户名',
        prefix: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 4.0), // 左侧加间距
          child: Icon(Icons.person, size: 20),
        ),
        suffix: controller.username.value.isNotEmpty
            ? GestureDetector(
                onTap: controller.clearUsername,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Icon(Icons.clear, size: 18),
                ),
              )
            : null,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Obx(
      () => CupertinoTextField(
        controller: controller.passwordController,
        placeholder: '请输入密码',
        obscureText: controller.obscurePassword.value,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 4.0), // 左侧加间距
          child: Icon(Icons.lock, size: 20),
        ),
        suffix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.password.value.isNotEmpty)
              GestureDetector(
                onTap: controller.clearPassword,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  child: Icon(Icons.clear, size: 18),
                ),
              ),
            GestureDetector(
              onTap: controller.togglePasswordVisibility,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Obx(
      () => CupertinoButton(
        onPressed:
            (controller.username.value.isNotEmpty &&
                controller.password.value.isNotEmpty &&
                controller.password.value.length >= 6 &&
                !controller.isLoading.value)
            ? () {
                FocusScope.of(Get.context!).unfocus();
                controller.login();
              }
            : null,
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        minimumSize: const Size(double.infinity, 50),
        disabledColor: Colors.blue.withAlpha(100),
        child: controller.isLoading.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '登录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            Get.snackbar('提示', '忘记密码功能开发中');
          },
          child: const Text('忘记密码？'),
        ),
        TextButton(
          onPressed: () {
            Get.snackbar('提示', '注册功能开发中');
          },
          child: const Text('注册账号'),
        ),
      ],
    );
  }
}
