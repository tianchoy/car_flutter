import 'package:flutter/cupertino.dart';

import 'reference_ui.dart';

class CustomBottomNavBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = CupertinoColors.systemBackground,
    this.selectedItemColor = AppColors.primary,
    this.unselectedItemColor = AppColors.secondaryText,
  });

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.home),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.mail),
          activeIcon: Icon(CupertinoIcons.mail_solid),
          label: '消息',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person),
          activeIcon: Icon(CupertinoIcons.person_fill),
          label: '我的',
        ),
      ],
      backgroundColor: backgroundColor.withValues(alpha: .96),
      activeColor: selectedItemColor,
      inactiveColor: unselectedItemColor,
      iconSize: 22,
      border: const Border(top: BorderSide(color: AppColors.divider)),
    );
  }
}
