import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../models/message/msg_model.dart';
import '../../widgets/reference_ui.dart';

/// 消息详情弹窗。
///
/// 列表点击与「推送点击后自动打开详情」共用同一份实现：
/// 前者有 BuildContext，后者由控制器在路由之外触发（使用 Get 的 overlay）。
class MessageDetailDialog {
  MessageDetailDialog._();

  static String typeName(int type) => switch (type) {
    1 => '设备告警',
    2 => '车辆动态',
    3 => '服务通知',
    _ => '系统消息',
  };

  static Future<void> show(
    MessageModel message, {
    BuildContext? context,
  }) async {
    if (context != null) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (_) => _build(message),
      );
      return;
    }
    await Get.dialog<void>(_build(message));
  }

  static CupertinoAlertDialog _build(MessageModel message) {
    return CupertinoAlertDialog(
      title: Text(message.title.isEmpty ? '暂无消息标题' : message.title),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content.isEmpty ? '暂无消息内容' : message.content,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                '时间：${message.createTime.isEmpty ? '--' : message.createTime}',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Get.back<void>(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
