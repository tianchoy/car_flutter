import 'package:flutter/cupertino.dart';

import 'reference_ui.dart';

/// 底部弹框的操作项。
class AppSheetAction<T> {
  const AppSheetAction({
    required this.label,
    this.value,
    this.isDefault = false,
    this.isDestructive = false,
    this.trailing,
  });

  /// 点击后通过 [showAppActionSheet] 返回的值。
  final T? value;

  /// 展示文案。
  final String label;

  /// 是否为当前选中/默认项：以主题色加粗展示。
  final bool isDefault;

  /// 是否为危险操作：以红色展示。
  final bool isDestructive;

  /// 选项右侧的附加内容（如设备在线/离线状态标识）。
  /// 提供时，行内改为「左文案 + 右附加」的两端对齐布局。
  final Widget? trailing;
}

/// 全宽底部弹框：左右与底部均铺满屏幕，仅顶部圆角。
///
/// 用于替代系统的 [CupertinoActionSheet]——后者按 iOS 规范自带左右 10px 边距、
/// 四角圆角并悬浮于底部，无法铺满屏幕。
///
/// 结构：标题（可选）+ 操作项列表 + 取消按钮；高度随内容自适应，
/// 超过 0.85 屏高时改为内部滚动。
Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  String? title,
  TextStyle? titleStyle,
  String? message,
  TextStyle? messageStyle,
  required List<AppSheetAction<T>> actions,
  bool showCancel = true,
  String cancelLabel = '取消',
}) {
  assert(actions.isNotEmpty, 'actions cannot be empty');
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (sheetContext) {
      final header = <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  titleStyle ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
            ),
          ),
        if (message != null && message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
                  messageStyle ??
                  const TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
          ),
      ];

      return Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          // 仅顶部圆角：底部直接贴住屏幕下缘，不产生留白。
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        // SafeArea 必须放在 Container 内部：背景色才会延伸到屏幕最底部
        // （含 Home Indicator 区域），内容则自动避开底部安全区；
        // 若 SafeArea 包在外面，背景会在 Home Indicator 处断开、露出页面背景。
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * .85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const _SheetDivider(),
                    _SheetRow(
                      label: actions[i].label,
                      color: actions[i].isDestructive
                          ? AppColors.danger
                          : actions[i].isDefault
                          ? AppColors.primary
                          : null,
                      bold: actions[i].isDefault,
                      trailing: actions[i].trailing,
                      onTap: () =>
                          Navigator.pop(sheetContext, actions[i].value),
                    ),
                  ],
                  if (showCancel) ...[
                    const _SheetDivider(thickness: 6),
                    _SheetRow(
                      label: cancelLabel,
                      bold: true,
                      onTap: () => Navigator.pop(sheetContext, null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    required this.onTap,
    this.color,
    this.bold = false,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool bold;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 16,
        color: color ?? AppColors.text,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        height: 52,
        alignment:
            trailing == null ? Alignment.center : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: trailing == null
            ? text
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider({this.thickness = 1});

  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(height: thickness, color: AppColors.divider);
  }
}
