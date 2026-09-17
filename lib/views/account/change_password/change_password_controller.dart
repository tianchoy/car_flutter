import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/shared/widgets/app_toast.dart';

import 'package:car/app/router_instance.dart';
import 'package:car/shared/models/api_response.dart';
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
    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
