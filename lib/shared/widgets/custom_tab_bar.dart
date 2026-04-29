import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Tab> tabs;
  final bool isScrollable;
  final Color indicatorColor;
  final double indicatorWeight;
  final EdgeInsetsGeometry indicatorPadding;
  final Color labelColor;
  final Color unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? backgroundColor;

  const CustomTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.indicatorColor = Colors.blue,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.labelColor = Colors.blue,
    this.unselectedLabelColor = Colors.grey,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        indicatorColor: indicatorColor,
        indicatorWeight: indicatorWeight,
        indicatorPadding: indicatorPadding,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        labelStyle:
            labelStyle ??
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle:
            unselectedLabelStyle ??
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
