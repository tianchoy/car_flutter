import 'package:flutter/cupertino.dart';

/// 统一的确认弹框：标题 + 提示内容 + 取消 / 确认（Cupertino 风格）。
///
/// 项目里多处直接手写 [CupertinoAlertDialog]，细节逐渐不一致（最典型的是
/// 标题与内容之间有的留间距、有的没留，看起来会贴在一起）。统一由这里承载：
/// - 内容与标题固定留 12px 间距；
/// - 取消返回 `false`、确认返回 `true`、点击遮罩关闭返回 `null`；
/// - 危险操作（删除 / 解绑 / 退出）用 [isDestructive] 让确认按钮显示为红色。
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool isDestructive = false,
}) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      // 与标题之间留出间距，避免两者贴得过近。
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        CupertinoDialogAction(
          isDefaultAction: !isDestructive,
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
