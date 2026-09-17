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
    this.busy = false,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final ObstructingPreferredSizeWidget? bottom;
  final bool showBottomNavBar;
  final Widget? floatingActionButton;
  final Color backgroundColor;
  /// 页面忙碌置为 true 时（如首页刷新），整页吞掉点击事件，
  /// 禁止用户在加载过程中操作任何控件（含导航栏与底部 Tab）。
  final bool busy;

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
    // 忙碌（如首页刷新）期间整页吞掉点击事件：AbsorbPointer 拦截冒泡，
    // 禁止用户在加载过程中操作任何控件（含导航栏按钮与底部 Tab）。
    if (!busy) return content;
    return Stack(
      children: [
        content,
        const Positioned.fill(
          child: AbsorbPointer(child: ColoredBox(color: Color(0x0A000000))),
        ),
      ],
    );
  }
}
