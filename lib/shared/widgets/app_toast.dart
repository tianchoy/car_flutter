import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 顶部轻提示：从顶部弹出的系统风格提示条。
///
/// 全部沿用 GetX snackbar 的默认样式，仅指定位置、文字色与展示时长。
class AppToast {
  AppToast._();

  static void show(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      colorText: Colors.black,
      duration: duration,
      // 白色半透明底：Get.snackbar 仅支持纯色/半透明色，无法叠加实时背景模糊。
      backgroundColor: Colors.white.withValues(alpha: 0.72),
    );
  }
}
