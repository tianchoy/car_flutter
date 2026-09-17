import 'package:flutter/cupertino.dart';

import 'package:car/widgets/app_bottom_sheet.dart';

class AppPopup {
  AppPopup._();

  /// 通用底部选择弹框（全宽、左右与底部均铺满屏幕）。
  ///
  /// [selectedOption] 对应的选项会以主题色加粗高亮。
  /// 点击某个选项或取消后，[onSelected] 会带回结果（取消为 null）。
  static Future<T?> show<T>({
    required BuildContext context,
    String title = '',
    String message = '',
    required List<T> options,
    required String Function(T option) displayText,
    String cancelText = '取消',
    void Function(T? selected)? onSelected,
    Function()? onCancel,
    bool isShowTitle = true,
    bool isShowMessage = true,
    bool isShowCancel = true,
    T? selectedOption,
  }) async {
    assert(options.isNotEmpty, 'options cannot be empty');

    final result = await showAppActionSheet<T>(
      context: context,
      title: isShowTitle && title.isNotEmpty ? title : null,
      message: isShowMessage && message.isNotEmpty ? message : null,
      actions: options
          .map(
            (option) => AppSheetAction<T>(
              label: displayText(option),
              value: option,
              isDefault: option == selectedOption,
            ),
          )
          .toList(),
      showCancel: isShowCancel,
      cancelLabel: cancelText,
    );

    if (result == null) {
      onCancel?.call();
      onSelected?.call(null);
    } else {
      onSelected?.call(result);
    }
    return result;
  }
}
