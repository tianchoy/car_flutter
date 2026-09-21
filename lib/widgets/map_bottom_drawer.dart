import 'package:flutter/cupertino.dart';

import 'reference_ui.dart';

/// 地图页面统一的底部抽屉：向上弹出 / 向下收起。
///
/// 弹出与收起共用**同一个** AnimationController（forward / reverse），
/// 因此两个方向的时长天然一致（都是 [duration]）；收起方向额外指定
/// reverseCurve，让面板平滑、完整地滑出屏幕，而不是「唰」地一下消失。
class MapBottomDrawer extends StatefulWidget {
  const MapBottomDrawer({
    super.key,
    required this.expanded,
    required this.onToggle,
    this.onCollapse,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = AppColors.page,
    this.duration = const Duration(milliseconds: 320),
  });

  /// 是否展开（true = 已弹出，false = 已收起）。
  final bool expanded;

  /// 点击收起态箭头时的状态切换入口。
  final VoidCallback onToggle;

  /// 顶部把手下滑时的收起入口：**幂等收起**（只会把状态置为收起）。
  ///
  /// 必须是幂等的，不能用 [onToggle]：一次下滑手势会连续多帧回调，
  /// 若每次都取反，面板就会在收起/弹出之间来回弹，表现为「弹两下、
  /// 滑三四次才收得起来」。未传入时回退到 [onToggle]。
  final VoidCallback? onCollapse;

  /// 面板内容（不含顶部把手，把手由抽屉自身提供）。
  final Widget child;

  /// 内容区内边距。
  final EdgeInsetsGeometry padding;

  /// 面板背景色。
  final Color backgroundColor;

  /// 单方向动画时长：收起与展开严格相同。
  final Duration duration;

  @override
  State<MapBottomDrawer> createState() => _MapBottomDrawerState();
}

class _MapBottomDrawerState extends State<MapBottomDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _panelOpacity;
  late final Animation<double> _arrowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    // 初次构建就直接落到目标状态，避免进入页面先播一次多余的动画。
    if (widget.expanded) _controller.value = 1;

    // 位移：弹出 easeOutCubic（起步即见、末端缓停）；
    // 收起 easeInOutCubic（起步平缓、中段匀速、末端收住），
    // 不会像 easeOut 那样一松手就窜下去。
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    // 面板淡出：收起时到后段才开始变透明，保证整个下滑过程都看得见，
    // 不会出现「滑到一半就没了」导致的收起很快的错觉。
    _panelOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutExpo,
      ),
    );

    // 收起态箭头：展开时前 35% 就淡出，收起时最后 35% 才浮现，
    // 避免箭头与面板同时可见造成重影。
    _arrowOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.35, curve: Curves.easeOut),
        reverseCurve: const Interval(0, 0.35, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MapBottomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (widget.expanded) {
      _controller.forward();
    } else {
      // reverse 与 forward 共用同一 duration，收起和弹出耗时一致。
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 面板：收起时整体向下滑出屏幕；收起后用 IgnorePointer
        // 避免隐形面板截获地图手势。
        IgnorePointer(
          ignoring: !widget.expanded,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _panelOpacity,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 12),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DragHandle(
                      onCollapse: widget.onCollapse ?? widget.onToggle,
                    ),
                    Padding(padding: widget.padding, child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 收起态：底部只保留圆形向上箭头，点击即重新弹出面板。
        FadeTransition(
          opacity: _arrowOpacity,
          child: IgnorePointer(
            ignoring: widget.expanded,
            child: Padding(
              // 留出底部安全区（iOS Home Indicator）高度，避免被系统横线压住。
              padding: const EdgeInsets.only(top: 8, bottom: 28),
              child: Center(
                child: _BouncingArrowButton(onTap: widget.onToggle),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 顶部短横线：按住下滑即收起整个面板。
///
/// 一次手势只触发一次收起（[_DragHandleState._consumed]）：
/// 拖动过程中 onVerticalDragUpdate 每帧都会回调，若不加节流，
/// 面板会被反复切换，出现「弹两下」。
class _DragHandle extends StatefulWidget {
  const _DragHandle({required this.onCollapse});

  final VoidCallback onCollapse;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _consumed = false;

  void _handleUpdate(DragUpdateDetails details) {
    if (_consumed || details.delta.dy <= 4) return;
    _consumed = true;
    widget.onCollapse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragDown: (_) => _consumed = false,
      onVerticalDragUpdate: _handleUpdate,
      onVerticalDragEnd: (_) => _consumed = false,
      onVerticalDragCancel: () => _consumed = false,
      child: SizedBox(
        height: 26,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// 收起态底部的圆形向上箭头：持续上下轻微跳动，引导用户点击展开更多信息。
///
/// 自带 AnimationController（仅在收起态挂载，展开后自动销毁），
/// 不给页面 Controller 增加额外的生命周期负担。
class _BouncingArrowButton extends StatefulWidget {
  const _BouncingArrowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BouncingArrowButton> createState() => _BouncingArrowButtonState();
}

class _BouncingArrowButtonState extends State<_BouncingArrowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // 向上 7px 的往复位移：幅度克制，只做引导，不喧宾夺主。
    _offset = Tween<double>(
      begin: 0,
      end: -7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.chevron_up,
            size: 24,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
