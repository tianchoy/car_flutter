import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RxString username = ''.obs;
  RxString password = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void Login() {
    // Get.toNamed(Routes.home);
    print('username: $username');
    print('password: $password');
    if (username.value.isEmpty) {
      Get.snackbar('title', '请输入用户名');
      return;
    }
    if (password.value.isEmpty) {
      Get.snackbar('title', '请输入密码');
      return;
    }
    if (username.value == 'admin' && password.value == '123456') {
      Get.back(result: true);
    } else {
      Get.snackbar('title', '用户名或密码错误');
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
