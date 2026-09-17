import 'package:flutter/cupertino.dart';

import 'package:car/shared/widgets/reference_ui.dart';
import 'package:car/utils/car_icon.dart';

/// 选择车标的底部弹框，供「添加设备」与「车辆详情-编辑」复用。
///
/// 返回选中的车标名称（[CarIconOption.name]），取消则返回 null。
/// [current] 为当前已选车标，用于高亮；[crossAxisCount] 为每行个数，默认每行 5 个。
Future<String?> showCarIconPicker({
  required BuildContext context,
  String current = '',
  int crossAxisCount = 5,
}) =>
    showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          // 高度随内容自适应：内容本身决定弹框高度，仅当超过 0.85 屏高时才限制并内部滚动。
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          // 用 SingleChildScrollView + 最小 Column，避免 Expanded 把弹框撑到 0.85 屏高。
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择车标',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _CarIconGrid(
                  current: current,
                  crossAxisCount: crossAxisCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );

class _CarIconGrid extends StatelessWidget {
  const _CarIconGrid({required this.current, required this.crossAxisCount});

  final String current;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final spacing = 8.0;
          final cellWidth =
              (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: carIconOptions
                .map(
                  (option) => SizedBox(
                    width: cellWidth,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => Navigator.pop(context, option.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          // 仅选中项显示蓝色边框，未选中不显示边框。
                          border: current == option.name
                              ? Border.all(color: AppColors.primary)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              carIconPreviewPath(option.name),
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
}
