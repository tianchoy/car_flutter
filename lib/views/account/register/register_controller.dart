import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/shared/widgets/app_toast.dart';

import 'package:car/app/router_instance.dart';
import 'package:car/shared/models/api_response.dart';
import 'package:car/utils/session.dart';
import 'register_repository.dart';

class RegisterController extends GetxController {
  RegisterController({RegisterRepository? repository})
    : _repository = repository ?? RegisterRepository();

  final RegisterRepository _repository;
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final phone = ''.obs;
  final code = ''.obs;
  final password = ''.obs;
  final countdown = 0.obs;
  final isSendingCode = false.obs;
  final isSubmitting = false.obs;
  final agreed = false.obs;
  final obscurePassword = true.obs;
  Timer? _timer;

  bool get canSendCode => !isSendingCode.value && countdown.value == 0;

  bool get isSubmitReady =>
      _isPhone(phone.value) &&
      RegExp(r'^\d{6}$').hasMatch(code.value) &&
      _isStrongPassword(password.value) &&
      agreed.value &&
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
  }

  Future<void> sendCode() async {
    final phone = phoneController.text.trim();
    if (!_isPhone(phone)) {
      _message('提示', '请输入正确的手机号');
      return;
    }
    isSendingCode.value = true;
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
      if (!isClosed) isSendingCode.value = false;
    }
  }

  Future<void> submit() async {
    final phone = phoneController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    if (!_isPhone(phone)) {
      _message('提示', '请输入正确的手机号');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _message('提示', '请输入6位短信验证码');
      return;
    }
    if (!_isStrongPassword(password)) {
      _message('提示', '密码需为8–16位且包含至少两种字符类型');
      return;
    }
    if (!agreed.value) {
      _message('提示', '请先阅读并同意用户协议');
      return;
    }
    isSubmitting.value = true;
    try {
      final response = await _repository.register(<String, dynamic>{
        'password': password,
        'confirmPassword': password,
        'phonenumber': phone,
        'smsCode': code,
      });
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        _message(
          '注册失败',
          result.message.isEmpty ? '注册失败，请稍后重试' : result.message,
        );
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final token = stringValue(data['access_token']).isNotEmpty
          ? stringValue(data['access_token'])
          : stringValue(data['token']);
      if (token.isNotEmpty) {
        await setSession(SessionKeys.token, token);
        Get.offAllNamed(Routes.home);
      } else {
        _message('成功', '注册成功，请使用新账号登录');
        Get.offNamed(Routes.login);
      }
    } catch (_) {
      _message('注册失败', '注册失败，请检查网络后重试');
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
    super.onClose();
  }
}
