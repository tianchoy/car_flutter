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
          Column(
            children: [
              Obx(
                () => CupertinoTextField(
                  controller: controller.usernameController,
                  placeholder: '请输入用户名',
                  prefix: const Icon(Icons.person),
                  suffix: controller.username.value.isNotEmpty
                      ? GestureDetector(
                          onTap: controller.clearUsername,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.clear, size: 20),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => CupertinoTextField(
                  controller: controller.passwordController,
                  placeholder: '请输入密码',
                  obscureText: true,
                  prefix: const Icon(Icons.lock),
                  suffix: controller.password.value.isNotEmpty
                      ? GestureDetector(
                          onTap: controller.clearPassword,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.clear, size: 20),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(
            () => CupertinoButton(
              onPressed:
                  (controller.username.value.isNotEmpty &&
                      controller.password.value.isNotEmpty &&
                      !controller.isLoading.value)
                  ? () {
                      FocusScope.of(context).unfocus();
                      controller.login();
                    }
                  : null,
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
              minimumSize: const Size(50, 50),
              disabledColor: Colors.grey.withAlpha(120),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('登录', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
