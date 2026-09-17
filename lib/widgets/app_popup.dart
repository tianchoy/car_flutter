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
    // 选中项前是否显示对号。首页选择车辆只需蓝色加粗字体，不需要对号。
    bool showSelectedCheck = true,
    // 当前选中项：会以加粗 + 主色（并可带勾选图标）高亮展示。
    T? selectedOption,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSelectedCheck && option == selectedOption)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        CupertinoIcons.checkmark,
                        size: 16,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  Text(
                    displayText(option),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: option == selectedOption
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: option == selectedOption
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.black,
                    ),
                  ),
                ],
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
