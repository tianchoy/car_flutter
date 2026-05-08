import 'package:flutter/cupertino.dart';

class AppDialog extends StatelessWidget {
  final String title; // 弹窗标题
  final String content; // 弹窗内容
  final String confirmText; // 确认按钮文本
  final String cancelText; // 取消按钮文本
  final VoidCallback onConfirm; // 确认按钮点击事件
  final VoidCallback onCancel; // 取消按钮点击事件
  final bool isShowCancel; // 是否显示取消按钮

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '确定',
    this.cancelText = '取消',
    required this.onConfirm,
    required this.onCancel,
    this.isShowCancel = true,
  });

  /// 对外统一调用的方法
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isShowCancel = true,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return AppDialog(
          title: title,
          content: content,
          confirmText: confirmText,
          cancelText: cancelText,
          isShowCancel: isShowCancel,
          onConfirm: () {
            Navigator.pop(context);
            if (onConfirm != null) {
              onConfirm();
            }
          },
          onCancel: () {
            Navigator.pop(context);
            if (onCancel != null) {
              onCancel();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        if (isShowCancel)
          CupertinoDialogAction(
            onPressed: onCancel,
            child: Text(
              cancelText,
              style: TextStyle(color: CupertinoColors.black, fontSize: 16),
            ),
          ),
        CupertinoDialogAction(
          onPressed: onConfirm,
          child: Text(
            confirmText,
            style: TextStyle(color: CupertinoColors.black, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
