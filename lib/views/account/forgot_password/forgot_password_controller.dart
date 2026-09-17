import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/models/api_response.dart';
import 'forgot_password_repository.dart';

class ForgotPasswordController extends GetxController {
  ForgotPasswordController({ForgotPasswordRepository? repository})
    : _repository = repository ?? ForgotPasswordRepository();

  final ForgotPasswordRepository _repository;
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;
  final confirmation = ''.obs;
  final step = 1.obs;
  final countdown = 0.obs;
  final isSending = false.obs;
  final isSubmitting = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirm = true.obs;
  Timer? _timer;

  bool get isIdentityReady =>
      _isPhone(phone.value) && RegExp(r'^\d{6}$').hasMatch(code.value);

  bool get isResetReady =>
      _isStrongPassword(password.value) &&
      password.value == confirmation.value &&
      !isSubmitting.value;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(
      () => phone.value = phoneController.text.trim(),
    );
    codeController.addListener(() => code.value = codeController.text.trim());
    passwordController.addListener(
      () => password.value = passwordController.text,
    );
    confirmController.addListener(
      () => confirmation.value = confirmController.text,
    );
  }

  Future<void> sendCode() async {
    final phone = phoneController.text.trim();
    if (!_isPhone(phone)) {
      _message('提示', '请输入正确的手机号');
      return;
    }
    isSending.value = true;
    try {
      final response = await _repository.sendSmsCode(phone);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (!result.isSuccess) {
        _message('发送失败', result.message.isEmpty ? '验证码发送失败' : result.message);
        return;
      }
      _startCountdown();
      _message('提示', '验证码已发送');
    } catch (_) {
      _message('发送失败', '验证码发送失败，请稍后重试');
    } finally {
      if (!isClosed) isSending.value = false;
    }
  }

  void nextStep() {
    if (!_isPhone(phoneController.text.trim())) {
      _message('提示', '请输入正确的手机号');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(codeController.text.trim())) {
      _message('提示', '请输入6位短信验证码');
      return;
    }
    step.value = 2;
  }

  Future<void> resetPassword() async {
    final password = passwordController.text;
    if (!_isStrongPassword(password)) {
      _message('提示', '密码需为8–16位且包含至少两种字符类型');
      return;
    }
    if (password != confirmController.text) {
      _message('提示', '两次输入的密码不一致');
      return;
    }
    isSubmitting.value = true;
    try {
      final response = await _repository.resetPassword(<String, dynamic>{
        'phonenumber': phoneController.text.trim(),
        'smsCode': codeController.text.trim(),
        'newPassword': password,
        'confirmPassword': confirmController.text,
      });
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (!result.isSuccess) {
        _message('重置失败', result.message.isEmpty ? '密码重置失败' : result.message);
        return;
      }
      step.value = 3;
    } catch (_) {
      _message('重置失败', '密码重置失败，请稍后重试');
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    countdown.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 1) {
        timer.cancel();
        countdown.value = 0;
      } else {
        countdown.value--;
      }
    });
  }

  bool _isPhone(String value) => RegExp(r'^1[3-9]\d{9}$').hasMatch(value);

  bool _isStrongPassword(String value) {
    if (value.length < 8 || value.length > 16) return false;
    var categories = 0;
    if (RegExp(r'[0-9]').hasMatch(value)) categories++;
    if (RegExp(r'[A-Za-z]').hasMatch(value)) categories++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) categories++;
    return categories >= 2;
  }

  void _message(String title, String message) => AppToast.show(title, message);

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
