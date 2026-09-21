import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'reference_assets.dart';

abstract final class AppColors {
  static const primary = Color(0xFF3485DF);
  static const primaryDark = Color(0xFF2874C7);
  static const page = Color(0xFFF5F7FA);
  static const text = Color(0xFF1F2937);
  static const secondaryText = Color(0xFF8A94A6);
  static const divider = Color(0xFFE8ECF2);
  static const success = Color(0xFF20B26B);
  static const warning = Color(0xFFFFA726);
  static const danger = Color(0xFFE85D5D);
}

class ReferencePage extends StatelessWidget {
  const ReferencePage({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.page,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 页面加载指示器：黑色半透明圆角底 + 白色菊花。
///
/// 浅色背景上单纯的 CupertinoActivityIndicator 很不明显，加一层半透明黑底后
/// 在任何背景色下都能看清。全 App 统一使用，替换 Center(child: CupertinoActivityIndicator())。
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.radius = 14, this.padding = 16});

  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoActivityIndicator(
        radius: radius,
        color: CupertinoColors.white,
      ),
    );
  }
}

/// 下拉刷新控件（全 App 统一样式）。
///
/// 系统默认的 CupertinoSliverRefreshControl 只有一个很小的菊花，不易察觉。
/// 这里改为「更大的指示器 + 状态文案」：拖拽时按进度逐步显现，达到阈值提示
/// 「松开立即刷新」，刷新中显示「正在刷新…」，状态一眼可见。
class AppRefreshControl extends StatelessWidget {
  const AppRefreshControl({
    super.key,
    required this.onRefresh,
    this.refreshTriggerPullDistance = 90,
    this.refreshIndicatorExtent = 72,
  });

  final RefreshCallback onRefresh;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      refreshTriggerPullDistance: refreshTriggerPullDistance,
      refreshIndicatorExtent: refreshIndicatorExtent,
      builder:
          (
            BuildContext context,
            RefreshIndicatorMode refreshState,
            double pulledExtent,
            double triggerDistance,
            double indicatorExtent,
          ) {
            final progress = triggerDistance <= 0
                ? 0.0
                : (pulledExtent / triggerDistance).clamp(0.0, 1.0);
            final refreshing =
                refreshState == RefreshIndicatorMode.refresh ||
                refreshState == RefreshIndicatorMode.done;
            // 刷新控件收起时 indicatorExtent 会趋近 0（例如 1.2），若直接按它约束
            // 内容就会溢出。这里用固定高度 + OverflowBox 让指示器保持自然尺寸，
            // 超出部分由 ClipRect 裁掉，形成「随下拉逐步露出」的效果。
            return SizedBox(
              height: indicatorExtent,
              child: ClipRect(
                child: OverflowBox(
                  maxHeight: refreshIndicatorExtent,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (refreshing)
                        const CupertinoActivityIndicator(radius: 14)
                      else
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CupertinoActivityIndicator.partiallyRevealed(
                            progress: progress,
                            radius: 14,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _hint(refreshState),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  String _hint(RefreshIndicatorMode state) {
    if (state == RefreshIndicatorMode.armed) return '松开立即刷新';
    if (state == RefreshIndicatorMode.refresh) return '正在刷新…';
    if (state == RefreshIndicatorMode.done) return '刷新完成';
    return '下拉刷新';
  }
}

/// 按内容自适应高度、按需换行的功能入口网格（替代固定行高的 GridView）。
/// 单元格宽度由父容器宽度均分，高度由内容决定，避免模块底部出现多余空白。
class FeatureGrid extends StatelessWidget {
  const FeatureGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 4,
    this.spacing = 3,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: cellWidth, child: child),
          ],
        );
      },
    );
  }
}

class ReferenceCard extends StatelessWidget {
  const ReferenceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.color = CupertinoColors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        if (action != null)
          CupertinoButton(
            onPressed: onTap,
            // 去掉 CupertinoButton 默认的上下内边距：默认竖向 padding 会把整行
            // 标题撑高，使标题看起来离卡片顶部过远（与无 action 的模块不一致）。
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(32, 24),
            child: Text(
              action!,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.online = false});

  final String label;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : AppColors.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 地图顶部统一的浮动标题条：图标 + 标题 + 右侧状态胶囊。
///
/// 带地图的页面（地理围栏 / 设备详情 / 轨迹回放 / 车辆跟踪）共用同一套样式，
/// 保证界面风格一致。
class MapTitleBar extends StatelessWidget {
  const MapTitleBar({
    super.key,
    required this.icon,
    required this.title,
    this.statusLabel,
    this.statusOnline = false,
  });

  final IconData icon;
  final String title;
  final String? statusLabel;
  final bool statusOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (statusLabel != null)
            StatusPill(label: statusLabel!, online: statusOnline),
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = AppColors.primary,
    this.badge,
    this.onTap,
    this.assetName,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;
  final String? assetName;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (assetName == null)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  )
                else
                  ReferenceFeatureIcon(
                    assetName: assetName!,
                    color: color,
                    semanticLabel: title,
                  ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      minimumSize: Size.zero,
      child: content,
    );
  }
}

class ReferenceTextField extends StatelessWidget {
  const ReferenceTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLength,
    this.enabled = true,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool enabled;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      prefix: prefix == null
          ? null
          : Padding(padding: const EdgeInsets.only(left: 14), child: prefix),
      suffix: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 8), child: suffix),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      maxLength: maxLength,
      enabled: enabled,
      textAlign: textAlign,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      placeholderStyle: const TextStyle(
        color: AppColors.secondaryText,
        fontSize: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
    );
  }
}

class MetricRing extends StatelessWidget {
  const MetricRing({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    // 0 表示不绘制高亮进度弧（首页两个指标不展示进度）。
    this.progress = 0,
  });

  final String value;
  final String unit;
  final String label;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 106,
            height: 106,
            child: CustomPaint(
              painter: _MetricRingPainter(
                color: color.withValues(alpha: .12),
                progressColor: color,
                progress: progress,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  children: [
                    TextSpan(text: value),
                    TextSpan(
                      text: unit,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRingPainter extends CustomPainter {
  const _MetricRingPainter({
    required this.color,
    required this.progressColor,
    required this.progress,
  });

  final Color color;
  final Color progressColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, basePaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MetricRingPainter oldDelegate) =>
      color != oldDelegate.color ||
      progressColor != oldDelegate.progressColor ||
      progress != oldDelegate.progress;
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.message = '暂无数据',
    this.icon = CupertinoIcons.tray,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: const Color(0xFFCBD2DC)),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppColors.secondaryText)),
      ],
    ),
  );
}

class ReferenceInput extends StatelessWidget {
  const ReferenceInput({
    super.key,
    required this.hint,
    this.controller,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLength,
    this.enabled = true,
    this.errorText,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool enabled;
  final String? errorText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final field = CupertinoTextField(
      controller: controller,
      placeholder: hint,
      prefix: prefix == null
          ? null
          : Padding(padding: const EdgeInsets.only(left: 14), child: prefix),
      suffix: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 8), child: suffix),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      maxLength: maxLength,
      enabled: enabled,
      autofocus: autofocus,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      placeholderStyle: const TextStyle(
        color: AppColors.secondaryText,
        fontSize: 14,
      ),
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: errorText == null ? AppColors.divider : AppColors.danger,
        ),
      ),
    );
    if (errorText == null || errorText!.isEmpty) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Text(
            errorText!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

Widget referenceInput(
  String hint, {
  TextEditingController? controller,
  Widget? prefix,
  Widget? suffix,
  bool obscureText = false,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  ValueChanged<String>? onSubmitted,
  ValueChanged<String>? onChanged,
  int? maxLength,
  bool enabled = true,
  String? errorText,
  bool autofocus = false,
}) => ReferenceInput(
  hint: hint,
  controller: controller,
  prefix: prefix,
  suffix: suffix,
  obscureText: obscureText,
  keyboardType: keyboardType,
  textInputAction: textInputAction,
  onSubmitted: onSubmitted,
  onChanged: onChanged,
  maxLength: maxLength,
  enabled: enabled,
  errorText: errorText,
  autofocus: autofocus,
);

class ReferenceButton extends StatelessWidget {
  const ReferenceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.filled = true,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final bool filled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label),
            ],
          );
    final button = filled
        ? CupertinoButton.filled(
            onPressed: loading ? null : onPressed,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            borderRadius: BorderRadius.circular(12),
            child: child,
          )
        : CupertinoButton(
            onPressed: loading ? null : onPressed,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: child,
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class ReferenceIconButton extends StatelessWidget {
  const ReferenceIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 22,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Icon(icon, size: size, color: color ?? AppColors.primary),
    );
  }
}

/// 时间区间选择卡片。
/// - 默认竖排（开始 / 结束两行），用于页面顶部；
/// - [horizontal]=true 时横排，用于播放控制面板等紧凑场景；
/// - 不再内置刷新按钮：选择时间即在对应控制器中请求数据（pickDate 内部已 load）。
class DateRangeCard extends StatelessWidget {
  const DateRangeCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onPickStart,
    required this.onPickEnd,
    this.labelStart = '开始时间',
    this.labelEnd = '结束时间',
    this.horizontal = false,
    this.showSeconds = false,
  });

  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final String labelStart;
  final String labelEnd;
  final bool horizontal;
  final bool showSeconds;

  String _pad(int value) => value.toString().padLeft(2, '0');
  String _format(DateTime value) =>
      '${value.year}-${_pad(value.month)}-${_pad(value.day)} '
      '${_pad(value.hour)}:${_pad(value.minute)}'
      '${showSeconds ? ':${_pad(value.second)}' : ''}';

  @override
  Widget build(BuildContext context) {
    final start = _cell(labelStart, _format(startTime), onPickStart);
    final end = _cell(labelEnd, _format(endTime), onPickEnd);
    if (horizontal) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          // 开始时间居左、结束时间居右，两端对齐。
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            start,
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                CupertinoIcons.arrow_right,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ),
            end,
          ],
        ),
      );
    }
    return ReferenceCard(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cell(labelStart, _format(startTime), onPickStart),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              // 显式给宽度，否则在 Column 中会被压成 0 宽而看不见。
              width: double.infinity,
              height: 1,
              child: ColoredBox(color: AppColors.divider),
            ),
          ),
          _cell(labelEnd, _format(endTime), onPickEnd),
        ],
      ),
    );
  }

  Widget _cell(String label, String value, VoidCallback onTap) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
        ),
      ],
    );
    return CupertinoButton(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal ? 8 : 14,
        vertical: 11,
      ),
      alignment: Alignment.centerLeft,
      onPressed: onTap,
      child: Row(
        // 横向模式按内容宽度收缩，配合外层 spaceBetween 让开始/结束时间分居两端；
        // 纵向模式仍撑满整行。
        mainAxisSize: horizontal ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!horizontal)
            const Icon(
              CupertinoIcons.calendar,
              color: AppColors.primary,
              size: 18,
            ),
          if (!horizontal) const SizedBox(width: 8),
          if (horizontal) text else Expanded(child: text),
        ],
      ),
    );
  }
}
