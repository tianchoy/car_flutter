import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/app/routes/router_instance.dart';
import 'package:car/models/api_response.dart';
import 'package:car/services/push/push_bootstrap.dart';
import 'package:car/services/unread_count_service.dart';
import 'package:car/utils/session.dart';
import 'set_password_repository.dart';

/// 设置登录密码：登录返回 `NEED_SET_PASSWORD`（已注册待补密码）或
/// `NEED_REGISTER`（首次短信登录）时，由登录页跳转过来补设/设置密码。
class SetPasswordController extends GetxController {
  SetPasswordController({SetPasswordRepository? repository})
    : _repository = repository ?? SetPasswordRepository();

  final SetPasswordRepository _repository;

  /// 登录页带过来的手机号与本次短信验证码。
  final SetPasswordArgs? args = SetPasswordArgs.parse(Get.arguments);

  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final obscurePassword = true.obs;
  final obscureConfirm = true.obs;
  final isSubmitting = false.obs;

  String get phone => args?.phonenumber ?? '';
  String get smsCode => args?.smsCode ?? '';

  /// 缺少登录上下文时无法补设密码（例如直接深链进入本页）。
  bool get hasContext => phone.isNotEmpty && smsCode.isNotEmpty;

  bool get isSubmitReady =>
      _isStrongPassword(password.value) &&
      confirmPassword.value.isNotEmpty &&
      password.value == confirmPassword.value &&
      !isSubmitting.value;

  @override
  void onInit() {
    super.onInit();
    passwordController.addListener(
      () => password.value = passwordController.text,
    );
    confirmController.addListener(
      () => confirmPassword.value = confirmController.text,
    );
  }

  Future<void> submit() async {
    final passwordValue = passwordController.text;
    final confirmValue = confirmController.text;
    if (!_isStrongPassword(passwordValue)) {
      _message('提示', '密码需为8–16位且包含至少两种字符类型');
      return;
    }
    if (confirmValue.isEmpty) {
      _message('提示', '请再次输入登录密码');
      return;
    }
    if (passwordValue != confirmValue) {
      _message('提示', '两次输入的密码不一致');
      return;
    }
    if (!hasContext) {
      _message('提示', '登录信息已失效，请重新获取验证码');
      Get.offAllNamed(Routes.login);
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final response = await _repository.setPassword(<String, dynamic>{
        'password': passwordValue,
        'confirmPassword': confirmValue,
        'phonenumber': phone,
        'smsCode': smsCode,
      });
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        _message(
          '设置失败',
          result.message.isEmpty ? '设置失败，请稍后重试' : result.message,
        );
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final token = stringValue(data['access_token']).isNotEmpty
          ? stringValue(data['access_token'])
          : stringValue(data['token']);
      if (token.isNotEmpty) {
        // 与 Web 端一致：补设密码成功即拿到凭证，直接完成登录。
        await setSession(SessionKeys.token, token);
        _message('成功', '密码设置成功');
        Get.offAllNamed(Routes.home);
        unawaited(PushBootstrap.schedulePostLoginInitialization());
        unawaited(UnreadCountService.to.refresh());
      } else {
        _message('成功', '密码设置成功，请使用新密码登录');
        Get.offAllNamed(Routes.login);
      }
    } catch (_) {
      _message('设置失败', '设置失败，请检查网络后重试');
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

  void _message(String title, String message) =>
      AppToast.show(title, message, duration: const Duration(seconds: 2));

  bool _isStrongPassword(String value) {
    if (value.length < 8 || value.length > 16) return false;
    var categories = 0;
    if (RegExp(r'[0-9]').hasMatch(value)) categories++;
    if (RegExp(r'[A-Za-z]').hasMatch(value)) categories++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) categories++;
    return categories >= 2;
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
