import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color backgroundColor;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.backgroundColor = Colors.white,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Get.back(),
            )
          : null,
      actions: actions,
      backgroundColor: backgroundColor,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 18),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
