import 'package:flutter/cupertino.dart';

import '../services/navigation_service.dart';
import 'bottom_nav_bar.dart';
import 'custom_app_bar.dart';
import 'reference_ui.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.showBottomNavBar = true,
    this.floatingActionButton,
    this.backgroundColor = AppColors.page,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final ObstructingPreferredSizeWidget? bottom;
  final bool showBottomNavBar;
  final Widget? floatingActionButton;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final navigationBar = CustomAppBar(
      title: title,
      showBackButton: showBackButton,
      actions: actions,
    );
    final tabBar = showBottomNavBar
        ? CustomBottomNavBar(
            currentIndex: NavigationService.getCurrentIndex(),
            onTap: NavigationService.navigateTo,
          )
        : null;

    final content = CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: navigationBar,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: tabBar == null ? 0 : tabBar.preferredSize.height,
              ),
              child: body,
            ),
          ),
          if (bottom != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(top: false, child: bottom!),
            ),
          if (tabBar != null)
            Align(alignment: Alignment.bottomCenter, child: tabBar),
          if (floatingActionButton != null)
            Positioned(
              right: 16,
              bottom: (tabBar?.preferredSize.height ?? 0) + 16,
              child: floatingActionButton!,
            ),
        ],
      ),
    );
    // 不再提供 busy 遮罩：刷新反馈统一由各页的 AppRefreshControl 呈现
    // （与消息页一致），避免加载时出现半透明遮罩层。
    return content;
  }
}
