import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = '确定',
    this.cancelText = '取消',
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            onCancel();
          },
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}
