import 'dart:async';
import 'dart:math' as math;

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

  /// iOS 底部安全区（Home Indicator，约 34pt）对底栏来说偏大，裁掉这一部分。
  static const double _iosBottomInsetTrim = 15;

  /// Android 的底部留白：手势导航下系统安全区为 0（底栏会贴住屏幕底边），
  /// 这里补到与 iOS 裁剪后相同的留白，保证两端观感一致；
  /// 若存在系统导航栏则保留系统值，避免底栏被系统栏压住。
  static const double _androidBottomInset = 34 - _iosBottomInsetTrim;

  /// 角标顶部相对图标顶部的偏移。
  static const double _badgeTop = 2;

  /// 角标左边缘与图标右边缘的重叠量：左边缘固定在图标右上角内侧，
  /// 因此角标变宽（两位数 / `99+`）时只向右延伸，左侧位置保持不变。
  static const double _badgeLeftOverlap = 7;

  /// 角标左边缘相对图标左侧的偏移（图标宽度随平台变化，这里同步计算）。
  static double get _badgeLeft =>
      (_isIOS ? _iosIconSize : _iconSize) - _badgeLeftOverlap;

  /// 角标文案字号：iOS 图标更大（25），角标同步放大一档。
  static double get _badgeFontSize => _isIOS ? 13 : 12;

  /// 角标高度，同时也是单字符角标的直径：
  /// 宽高相等 → 正圆；两位数 / `99+` 时宽度被文案撑开 → 椭圆胶囊。
  static double get _badgeSize => _isIOS ? 19 : 17;

  /// 多字符角标左右内边距：与 [_badgeSize] 一起决定胶囊的圆润程度。
  static const double _badgeHorizontalPadding = 5;

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
      data: _adjustedSafeArea(context),
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

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// 底栏需要额外留出的底部空间：
  /// - iOS：把系统安全区（Home Indicator 约 34pt）收紧 [_iosBottomInsetTrim]；
  /// - Android：至少补到 [_androidBottomInset]，与 iOS 裁剪后的留白一致。
  static double _bottomInset(BuildContext context) {
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    if (_isIOS) return math.max(systemBottom - _iosBottomInsetTrim, 0);
    return math.max(systemBottom, _androidBottomInset);
  }

  /// 底栏实际占用高度 = 内容高度 + 底部留白。
  ///
  /// 页面正文底部留白与悬浮按钮偏移都按它计算，避免内容落进底栏的底部留白区域。
  /// [preferredSize] 则与 CupertinoTabBar 保持一致，只包含内容高度（底部安全区
  /// 依赖 BuildContext，getter 里取不到）。
  static double reservedHeight(BuildContext context) =>
      _barHeight + _bottomInset(context);

  /// CupertinoTabBar 用 `viewPadding.bottom` 计算底栏的额外高度，这里替换子树里的
  /// 安全区（同步改 padding，避免两个值不一致）。
  MediaQueryData _adjustedSafeArea(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = _bottomInset(context);
    if (bottom == media.viewPadding.bottom) return media;
    return media.copyWith(
      viewPadding: media.viewPadding.copyWith(bottom: bottom),
      padding: media.padding.copyWith(bottom: bottom),
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
  ///
  /// 角标以**左边缘**定位（[_badgeLeft]）：个位数保持正圆时左侧不动，
  /// 两位数 / `99+` 变宽后只向右延伸，消息图标与角标左边缘的相对位置恒定。
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
        Positioned(top: _badgeTop, left: _badgeLeft, child: _buildBadge(badge)),
      ],
    );
  }

  /// 红底白字角标：超过 99 由 [UnreadCountService.badgeText] 输出 `99+`。
  ///
  /// - 个位数 → 宽高相等（[_badgeSize] × [_badgeSize]）+ [StadiumBorder]，
  ///   渲染为正圆；
  /// - 两位数 / `99+` → 高度不变、宽度由文案与内边距撑开，呈椭圆胶囊。
  Widget _buildBadge(String text) {
    // 角标只可能是数字或 `99+`，按字符数即可区分两种形态。
    final isSingleCharacter = text.length <= 1;
    return Container(
      height: _badgeSize,
      width: isSingleCharacter ? _badgeSize : null,
      constraints: isSingleCharacter
          ? null
          : BoxConstraints(minWidth: _badgeSize),
      padding: isSingleCharacter
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: _badgeHorizontalPadding),
      // 文本块按行高（= 字号）计算，配合居中对齐即可让数字落在角标正中心；
      // 不再用大于 1 的行高，否则行框自带的上下留白会把数字顶偏。
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: AppColors.badge,
        // 圆角始终取高度的一半：正方形时为正圆，变宽后成为椭圆胶囊。
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: CupertinoColors.white,
          fontSize: _badgeFontSize,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
