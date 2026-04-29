import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../components/widget/buildBody.dart';
import '../../components/widget/buildContainer.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '登陆',
      showBackButton: true,
      showBottomNavBar: false,
      actions: [
        TextButton(
          onPressed: () {
            Get.snackbar('title', 'message');
          },
          child: Text('注册'),
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BuildBody(
      child: Column(
        children: [
          BuildContainer(
            child: Column(
              children: [
                Obx(
                  () => CupertinoTextField(
                    // 将可观察变量的值赋给 controller
                    controller: TextEditingController(
                      text: controller.username.value,
                    ),
                    placeholder: '请输入用户名',
                    prefix: Icon(Icons.person),
                    suffix: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        controller.usernameController.clear();
                        controller.username.value = '';
                      },
                    ),
                    // 当用户输入时，更新可观察变量的值
                    onChanged: (value) => controller.username.value = value,
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => CupertinoTextField(
                    controller: TextEditingController(
                      text: controller.password.value,
                    ),
                    placeholder: '请输入密码',
                    prefix: Icon(Icons.lock),
                    onChanged: (value) => controller.password.value = value,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: () {
              controller.Login();
            },
            child: Text('登录'),
          ),
        ],
      ),
    );
  }
}
