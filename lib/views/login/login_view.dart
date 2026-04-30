// login_view.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: controller.usernameController,
                  placeholder: '请输入用户名',
                  prefix: const Icon(Icons.person),
                  suffix: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearUsername,
                  ),
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  controller: controller.passwordController,
                  placeholder: '请输入密码',
                  obscureText: true,
                  prefix: const Icon(Icons.lock),
                  suffix: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearPassword,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => CupertinoButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      controller.login();
                    },
              color: Colors.blue,
              child: controller.isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('登录'),
            ),
          ),
        ],
      ),
    );
  }
}
