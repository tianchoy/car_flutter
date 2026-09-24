import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import '../../app/routes/route_arguments.dart';
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

  /// 发送验证码前置条件：手机号需为合法号码（与 Web 端校验一致），
  /// 而不是仅判断长度。
  bool get canSendSmsCode =>
      _isPhone(phone.value) && smsCountdown.value == 0 && !isLoading.value;

  bool get isFormValid => useSmsLogin.value
      ? _isPhone(phone.value) &&
            RegExp(r'^\d{6}$').hasMatch(smsCode.value) &&
            !isLoading.value
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
      // 该手机号已注册但没设置密码：补设密码需要短信验证码，引导改用验证码登录。
      if (requiresPasswordSetup(
        message: error.message,
        payload: error.payload,
      )) {
        _showMessage('提示', '该手机号尚未设置登录密码，请使用验证码登录后设置');
        return;
      }
      _showMessage('登录失败', error.message);
    } catch (_) {
      _showMessage('登录失败', '登录服务连接失败，请检查网络后重试');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _smsLogin() async {
    if (!_isPhone(phone.value)) {
      _showMessage('提示', '请输入正确的手机号');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(smsCode.value)) {
      _showMessage('提示', '请输入6位短信验证码');
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
      // 手机号已注册但尚未设置密码（NEED_SET_PASSWORD）、或该手机号还没注册
      //（NEED_REGISTER）：两者都跳设置密码页补设密码，并带上手机号与本次验证码。
      if (requiresPasswordSetup(
        message: error.message,
        payload: error.payload,
      )) {
        unawaited(
          Get.toNamed(
            Routes.setPassword,
            arguments: SetPasswordArgs(
              phonenumber: phone.value.trim(),
              smsCode: smsCode.value.trim(),
            ),
          ),
        );
        return;
      }
      _showMessage('登录失败', error.message);
    } catch (_) {
      _showMessage('登录失败', '登录服务连接失败，请检查网络后重试');
    } finally {
      isLoading.value = false;
    }
  }

  /// 切换登录方式：与 Web 端 `toggleLoginMode` 一致，切回密码登录时
  /// 清空验证码并停止倒计时，避免残留旧验证码/倒计时。
  void setLoginMode(bool useSms) {
    if (useSmsLogin.value == useSms) return;
    useSmsLogin.value = useSms;
    if (useSms) return;
    smsCodeController.clear();
    smsCode.value = '';
    _smsTimer?.cancel();
    _smsTimer = null;
    smsCountdown.value = 0;
  }

  bool _isPhone(String value) => RegExp(r'^1[3-9]\d{9}$').hasMatch(value);

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
    // 刻意不 dispose 下面这些 TextEditingController：
    // GetX 在重复进入同一路由（或绑定被重新执行）时会替换旧的控制器实例并触发
    // onClose，而旧的登录页 widget 可能仍挂在路由栈上；一旦它的输入框在输入或
    // 重建时访问已销毁的 controller，就会抛
    //「A TextEditingController was used after being disposed」（输入无效 / 红屏）。
    // TextEditingController 不持有外部资源，监听它的输入框在自身销毁时会移除监听，
    // 因此交给 GC 回收即可；真正需要释放的是定时器（已在此取消）。
    super.onClose();
  }
}
