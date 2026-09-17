import 'package:flutter/cupertino.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTabBar({
    super.key,
    required this.tabs,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.labelStyle,
    this.unselectedLabelStyle,
  });

  final List<Widget> tabs;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 9),
                minimumSize: Size.zero,
                onPressed: onTap == null ? null : () => onTap!(index),
                color: index == currentIndex
                    ? CupertinoColors.activeBlue
                    : null,
                borderRadius: BorderRadius.circular(9),
                child: DefaultTextStyle.merge(
                  style: index == currentIndex
                      ? labelStyle ??
                            const TextStyle(fontWeight: FontWeight.w600)
                      : unselectedLabelStyle ??
                            const TextStyle(color: CupertinoColors.systemGrey),
                  child: tabs[index],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
