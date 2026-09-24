import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/unread_count_service.dart';
import 'reference_ui.dart';

class CustomBottomNavBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// 底栏高度（不含底部安全区）。CupertinoTabBar 内部把「图标 + 文字」整体
  /// 底部对齐，加高底栏会让图标上方的留白变大，但图标与文字的间距也会同比
  /// 变大，因此与 [_iconTopPadding] 配合使用。
  static const double _barHeight = 56;

  /// 图标顶部内边距：图标位于居中的 Expanded 区域内，加该内边距后图标会下移
  /// 一半的距离，从而与顶部分割线拉开空间，同时略微收紧图标与文字的间距。
  static const double _iconTopPadding = 6;

  /// 图标尺寸：iOS 观感偏小，单独放大一档；其它平台保持原尺寸。
  static const double _iconSize = 22;
  static const double _iosIconSize = 25;

  /// iOS 底部安全区（Home Indicator，约 34pt）对底栏来说偏大，收紧一部分让底栏
  /// 整体更矮；Android 的系统导航栏高度不能压，保持原样。
  static const double _iosBottomInsetTrim = 12;

  /// 角标相对图标右上角的偏移：负数 = 向右溢出图标区域。
  static const double _badgeRight = -10;
  static const double _badgeTop = 3;

  /// 角标文案字号（比图标下方文字明显，但仍是小号数字）。
  static const double _badgeFontSize = 10;

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
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: _trimmedSafeArea(context),
      // 未读角标跟随全局未读数变化：只有「消息」项带角标。
      child: Obx(() {
        final badge = UnreadCountService.to.badgeText;
        return CupertinoTabBar(
          currentIndex: currentIndex,
          onTap: _handleTap,
          height: _barHeight,
          items: [
            _buildItem(CupertinoIcons.home, CupertinoIcons.house_fill, '首页'),
            _buildItem(
              CupertinoIcons.mail,
              CupertinoIcons.mail_solid,
              '消息',
              badge: badge,
            ),
            _buildItem(CupertinoIcons.person, CupertinoIcons.person_fill, '我的'),
          ],
          backgroundColor: backgroundColor.withValues(alpha: .96),
          activeColor: selectedItemColor,
          inactiveColor: unselectedItemColor,
          iconSize: _isIOS ? _iosIconSize : _iconSize,
          border: const Border(top: BorderSide(color: AppColors.divider)),
        );
      }),
    );
  }

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// CupertinoTabBar 用 `viewPadding.bottom` 计算底栏的额外高度，这里只把 iOS
  /// 的安全区收紧一些（同步改 padding，避免子树里两个值不一致）。
  MediaQueryData _trimmedSafeArea(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.viewPadding.bottom;
    if (!_isIOS || bottom <= 0) return media;
    final trimmed = (bottom - _iosBottomInsetTrim).clamp(0.0, bottom);
    return media.copyWith(
      viewPadding: media.viewPadding.copyWith(bottom: trimmed),
      padding: media.padding.copyWith(bottom: trimmed),
    );
  }

  /// 切换 tab 时顺带同步一次未读数：除登录、推送与消息页自身外，
  /// 这是唯一能感知「服务端新增未读」的时机（其它 tab 页没有轮询）。
  void _handleTap(int index) {
    onTap(index);
    unawaited(UnreadCountService.to.refresh());
  }

  BottomNavigationBarItem _buildItem(
    IconData icon,
    IconData activeIcon,
    String label, {
    String? badge,
  }) {
    return BottomNavigationBarItem(
      icon: _buildIcon(icon, badge: badge),
      activeIcon: _buildIcon(activeIcon, badge: badge),
      label: label,
    );
  }

  /// 图标 + 可选角标：角标叠在图标右上角外侧，允许溢出图标区域（Stack 不裁剪）。
  Widget _buildIcon(IconData icon, {String? badge}) {
    final target = Padding(
      padding: const EdgeInsets.only(top: _iconTopPadding),
      child: Icon(icon),
    );
    if (badge == null) return target;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        target,
        Positioned(
          top: _badgeTop,
          right: _badgeRight,
          child: _buildBadge(badge),
        ),
      ],
    );
  }

  /// 红底白字胶囊：超过 99 由 [UnreadCountService.badgeText] 输出 `99+`。
  Widget _buildBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    constraints: const BoxConstraints(minWidth: 15),
    decoration: BoxDecoration(
      color: AppColors.badge,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: CupertinoColors.white,
        fontSize: _badgeFontSize,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
