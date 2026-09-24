import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import '../../app/routes/router_instance.dart';
import '../../models/api_response.dart';
import '../../services/push/push_bootstrap.dart';
import '../../services/unread_count_service.dart';
import 'login_repository.dart';

class LoginController extends GetxController {
  LoginController({LoginRepository? loginRepository})
    : _loginRepository = loginRepository ?? LoginRepository();

  final LoginRepository _loginRepository;
  final formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController smsCodeController = TextEditingController();

  final RxString username = ''.obs;
  final RxString password = ''.obs;
  final RxString phone = ''.obs;
  final RxString smsCode = ''.obs;
  final RxInt smsCountdown = 0.obs;
  final RxBool useSmsLogin = false.obs;
  final RxBool agreed = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  Timer? _smsTimer;

  bool get canSendSmsCode =>
      phone.value.length >= 11 && smsCountdown.value == 0 && !isLoading.value;

  bool get isFormValid => useSmsLogin.value
      ? phone.value.isNotEmpty && smsCode.value.isNotEmpty && !isLoading.value
      : username.value.isNotEmpty &&
            password.value.isNotEmpty &&
            !isLoading.value;

  @override
  void onInit() {
    super.onInit();
    usernameController.addListener(
      () => username.value = usernameController.text.trim(),
    );
    passwordController.addListener(
      () => password.value = passwordController.text,
    );
    phoneController.addListener(
      () => phone.value = phoneController.text.trim(),
    );
    smsCodeController.addListener(
      () => smsCode.value = smsCodeController.text.trim(),
    );
  }

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  Future<void> sendSmsCode() async {
    if (!canSendSmsCode) return;
    isLoading.value = true;
    try {
      await _loginRepository.sendSmsCode(phone.value);
      smsCountdown.value = 60;
      _smsTimer?.cancel();
      _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (smsCountdown.value <= 1) {
          timer.cancel();
          smsCountdown.value = 0;
        } else {
          smsCountdown.value--;
        }
      });
      _showMessage('提示', '验证码已发送');
    } on ApiBusinessException catch (error) {
      _showMessage('发送失败', error.message);
    } catch (_) {
      _showMessage('发送失败', '验证码发送失败，请稍后重试');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    if (useSmsLogin.value) {
      await _smsLogin();
      return;
    }
    final normalizedUsername = username.value.trim();
    if (normalizedUsername.isEmpty) {
      _showMessage('提示', '请输入用户名');
      return;
    }
    if (password.value.isEmpty) {
      _showMessage('提示', '请输入密码');
      return;
    }
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _loginRepository.login(normalizedUsername, password.value);
      _showMessage('成功', '登录成功');
      Get.offAllNamed(Routes.home);
      _schedulePostLoginTasks();
    } on ApiBusinessException catch (error) {
      _showMessage('登录失败', error.message);
    } catch (_) {
      _showMessage('登录失败', '登录服务连接失败，请检查网络后重试');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _smsLogin() async {
    if (phone.value.isEmpty) {
      _showMessage('提示', '请输入手机号');
      return;
    }
    if (smsCode.value.isEmpty) {
      _showMessage('提示', '请输入验证码');
      return;
    }
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _loginRepository.smsLogin(phone.value, smsCode.value);
      _showMessage('成功', '登录成功');
      Get.offAllNamed(Routes.home);
      _schedulePostLoginTasks();
    } on ApiBusinessException catch (error) {
      _showMessage('登录失败', error.message);
    } catch (_) {
      _showMessage('登录失败', '登录服务连接失败，请检查网络后重试');
    } finally {
      isLoading.value = false;
    }
  }

  void clearUsername() => usernameController.clear();
  void clearPassword() => passwordController.clear();

  /// 登录成功并完成首页跳转后的收尾动作（密码登录与短信登录共用）。
  ///
  /// - 延后初始化推送，避免与登录、首屏数据请求争抢资源；
  /// - 立即同步「消息」tab 的未读角标（此时已持有有效 token）。
  void _schedulePostLoginTasks() {
    unawaited(PushBootstrap.schedulePostLoginInitialization());
    unawaited(UnreadCountService.to.refresh());
  }

  void _showMessage(String title, String message) {
    AppToast.show(title, message, duration: const Duration(seconds: 2));
  }

  @override
  void onClose() {
    _smsTimer?.cancel();
    usernameController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    smsCodeController.dispose();
    super.onClose();
  }
}
