import 'package:flutter/cupertino.dart';

class AppPopup {
  static Future<T?> show<T>({
    required BuildContext context,
    String title = '',
    String message = '',
    required List<T> options,
    required String Function(T option)
    displayText, //displayText: (item) => item['name'] as String,
    String cancelText = '取消',
    void Function(T? selected)? onSelected,
    Function()? onCancel,
    bool isShowTitle = true,
    bool isShowMessage = true,
    bool isShowCancel = true,
  }) {
    // 确保有内容可显示
    assert(options.isNotEmpty, 'options cannot be empty');

    return showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: isShowTitle && title.isNotEmpty
            ? Text(
                title,
                style: const TextStyle(
                  color: CupertinoColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        message: isShowMessage && message.isNotEmpty
            ? Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.black,
                ),
              )
            : null,
        actions: [
          ...options.map(
            (option) => CupertinoActionSheetAction(
              child: Text(
                displayText(option),
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
              ),
              onPressed: () {
                onSelected?.call(option);
                Navigator.pop(context, option);
              },
            ),
          ),
          if (isShowCancel)
            CupertinoActionSheetAction(
              isDefaultAction: true, // 取消按钮常用样式
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
              onPressed: () {
                onCancel?.call();
                onSelected?.call(null);
                Navigator.pop(context, null);
              },
            ),
        ],
      ),
    );
  }
}
