import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/models/api_response.dart';
import 'package:car/utils/session.dart';
import 'change_password_repository.dart';

class ChangePasswordController extends GetxController {
  ChangePasswordController({ChangePasswordRepository? repository})
    : _repository = repository ?? ChangePasswordRepository();

  final ChangePasswordRepository _repository;
  final oldController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  final isSubmitting = false.obs;
  final oldObscure = true.obs;
  final newObscure = true.obs;
  final confirmObscure = true.obs;

  // 三个输入框内容的实时镜像：TextEditingController 本身不可被 Obx 观察，
  // 这里同步到 Rx 上，用于驱动「确认修改」按钮的可点击状态。
  final oldPassword = ''.obs;
  final newPassword = ''.obs;
  final confirmPassword = ''.obs;

  // 用户是否已经填写过该输入框：未填写过就不报错，避免一进页面就满屏红字。
  final oldTouched = false.obs;
  final newTouched = false.obs;
  final confirmTouched = false.obs;

  @override
  void onInit() {
    super.onInit();
    oldController.addListener(_syncFromFields);
    newController.addListener(_syncFromFields);
    confirmController.addListener(_syncFromFields);
  }

  void _syncFromFields() {
    oldPassword.value = oldController.text;
    newPassword.value = newController.text;
    confirmPassword.value = confirmController.text;
    // 一旦输入过内容就标记为已填写（之后清空也会保留，以便提示必填）。
    if (oldController.text.isNotEmpty) oldTouched.value = true;
    if (newController.text.isNotEmpty) newTouched.value = true;
    if (confirmController.text.isNotEmpty) confirmTouched.value = true;
  }

  /// 表单是否已填写完整且合法：
  /// 当前密码非空、新密码符合强度要求且不同于当前密码、两次输入一致。
  /// 供「确认修改」按钮判断是否可点击（在 Obx 内读取会自动订阅这些 Rx）。
  bool get canSubmit {
    final old = oldPassword.value;
    final next = newPassword.value;
    return old.isNotEmpty &&
        _isStrongPassword(next) &&
        next != old &&
        confirmPassword.value == next;
  }

  /// 各输入框的实时错误文案（null 表示当前无错误、不展示）。
  /// 在 Obx 内读取会自动订阅依赖的 Rx，因此输入时可即时更新。
  String? get oldPasswordError {
    if (!oldTouched.value) return null;
    if (oldPassword.value.isEmpty) return '请输入当前密码';
    return null;
  }

  String? get newPasswordError {
    if (!newTouched.value) return null;
    final next = newPassword.value;
    if (next.isEmpty) return '请输入新密码';
    if (!_isStrongPassword(next)) {
      return '密码需为 8–16 位，且包含数字、字母、特殊字符中的至少两种';
    }
    if (next == oldPassword.value) return '新密码不能与当前密码相同';
    return null;
  }

  String? get confirmPasswordError {
    if (!confirmTouched.value) return null;
    final confirm = confirmPassword.value;
    if (confirm.isEmpty) return '请再次输入新密码';
    if (confirm != newPassword.value) return '两次输入的密码不一致';
    return null;
  }

  Future<void> submit() async {
    final oldPassword = oldController.text;
    final newPassword = newController.text;
    if (oldPassword.isEmpty) {
      _message('提示', '请输入当前密码');
      return;
    }
    if (!_isStrongPassword(newPassword)) {
      _message('提示', '密码需为8–16位且包含至少两种字符类型');
      return;
    }
    if (oldPassword == newPassword) {
      _message('提示', '新密码不能与当前密码相同');
      return;
    }
    if (newPassword != confirmController.text) {
      _message('提示', '两次输入的密码不一致');
      return;
    }
    isSubmitting.value = true;
    try {
      final response = await _repository.changePassword(<String, dynamic>{
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmController.text,
      });
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (!result.isSuccess) {
        _message('修改失败', result.message.isEmpty ? '密码修改失败' : result.message);
        return;
      }
      await clearAuthenticatedSession();
      _message('成功', '密码修改成功，请重新登录');
      Get.offAllNamed(Routes.login);
    } catch (_) {
      _message('修改失败', '密码修改失败，请检查网络后重试');
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

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
    oldController.removeListener(_syncFromFields);
    newController.removeListener(_syncFromFields);
    confirmController.removeListener(_syncFromFields);
    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
