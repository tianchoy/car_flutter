// login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_respository.dart';

class LoginController extends GetxController {
  final LoginRepository loginRepository = LoginRepository();

  // TextEditingController 用于控制输入框
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Rx 变量用于响应式监听
  final RxString username = ''.obs;
  final RxString password = ''.obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    usernameController.addListener(() {
      username.value = usernameController.text.trim();
    });
    passwordController.addListener(() {
      password.value = passwordController.text.trim();
    });
  }

  void login() async {
    if (username.value.isEmpty) {
      Get.snackbar('提示', '请输入用户名');
      return;
    }

    if (password.value.isEmpty) {
      Get.snackbar('提示', '请输入密码');
      return;
    }

    isLoading.value = true;
    try {
      await loginRepository.login(username.value, password.value);
    } catch (e) {
      Get.snackbar('错误', '登录失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearUsername() {
    usernameController.clear();
    username.value = '';
  }

  void clearPassword() {
    passwordController.clear();
    password.value = '';
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
