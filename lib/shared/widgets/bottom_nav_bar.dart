// shared/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final double elevation;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.selectedItemColor = Colors.blue,
    this.unselectedItemColor = Colors.grey,
    this.elevation = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: _buildNavItems(),
          backgroundColor: backgroundColor,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          elevation: elevation,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: '首页'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.mail), label: '消息'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: '我'),
    ];
  }
}
