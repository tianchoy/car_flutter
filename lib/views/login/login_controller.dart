// login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_respository.dart';

class LoginController extends GetxController {
  final LoginRepository loginRepository = LoginRepository();

  // 表单状态
  final formKey = GlobalKey<FormState>();

  // TextEditingController 用于控制输入框
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Rx 变量用于响应式监听
  final RxString username = ''.obs;
  final RxString password = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  // 计算属性
  bool get isFormValid =>
      username.value.isNotEmpty && password.value.isNotEmpty;

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

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void login() async {
    // 表单验证
    if (username.value.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入用户名',
        snackPosition: SnackPosition.TOP,
        colorText: Colors.black,
      );
      return;
    }

    if (password.value.isEmpty) {
      Get.snackbar(
        '提示',
        '请输入密码',
        snackPosition: SnackPosition.TOP,
        colorText: Colors.black,
      );
      return;
    }

    if (password.value.length < 6) {
      Get.snackbar(
        '提示',
        '密码长度不能少于6位',
        snackPosition: SnackPosition.TOP,
        colorText: Colors.black,
      );
      return;
    }

    // 防止重复提交
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      await loginRepository.login(username.value, password.value);
      // 登录成功后的处理
      Get.snackbar(
        '成功',
        '登录成功',
        snackPosition: SnackPosition.TOP,
        colorText: Colors.black,
      );
      // 跳转到主页
      Get.offAllNamed('/');
    } catch (e) {
      Get.snackbar(
        '错误',
        '登录失败：$e',
        snackPosition: SnackPosition.TOP,
        colorText: Colors.black,
      );
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
