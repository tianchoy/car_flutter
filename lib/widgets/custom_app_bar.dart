import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'reference_ui.dart';

class CustomAppBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.backgroundColor = CupertinoColors.systemBackground,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color backgroundColor;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final trailing = actions;
    return CupertinoNavigationBar(
      backgroundColor: backgroundColor.withValues(alpha: .96),
      border: const Border(bottom: BorderSide(color: AppColors.divider)),
      automaticallyImplyLeading: false,
      // CupertinoNavigationBar 默认左右内边距为 16，会让返回键/功能键偏向中间；
      // 收窄到 8 使其向屏幕两侧靠拢。
      padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
      leading: showBackButton
          ? GestureDetector(
              onTap: Get.back,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 36,
                height: 44,
                child: Center(
                  child: Icon(
                    CupertinoIcons.back,
                    color: AppColors.text,
                    size: 24,
                  ),
                ),
              ),
            )
          : null,
      middle: Text(
        title,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing == null || trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: trailing),
    );
  }

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Size get preferredSize => const Size.fromHeight(44);
}
