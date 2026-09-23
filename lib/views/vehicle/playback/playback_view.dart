import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/services/url.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/map_bottom_drawer.dart';
import 'package:car/widgets/map_marker_bubble.dart';
import 'package:car/widgets/reference_ui.dart';
import 'package:car/utils/car_icon.dart';
import 'playback_controller.dart';

class PlaybackView extends GetView<PlaybackController> {
  const PlaybackView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '轨迹回放',
      showBackButton: true,
      showBottomNavBar: false,
      body: ReferencePage(
        child: Stack(
          children: [
            // 地图铺满整屏：底部面板改为浮在地图之上的可收起抽屉，
            // 收起后地图的可视区域与地理围栏页保持一致。
            Positioned.fill(child: Obx(() => _buildMap())),
            _buildTopBar(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Obx(() => _buildPanel(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final device = controller.device;
    final plate =
        <String?>[
          device?.deviceName,
          device?.plateNo,
          device?.deviceNo,
          device?.deviceId,
        ].firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        ) ??
        '未命名设备';
    final status = controller.device?.deviceStatus ?? '';
    final online = status.toLowerCase() == 'online';
    // 与地理围栏 / 设备详情 / 车辆跟踪保持一致：地图顶部浮动标题条
    //（图标 + 名称 + 在线状态），不再是整条通栏白底。
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: MapTitleBar(
        icon: CupertinoIcons.car_detailed,
        title: plate,
        statusLabel: online ? '在线' : '离线',
        statusOnline: online,
      ),
    );
  }

  Widget _buildMap() {
    // 还没有可用坐标时显示占位加载，避免先渲染默认坐标（北京）再跳过去；
    // 轨迹点就绪后以第一个轨迹点作为中心兜底。
    final initial =
        controller.initialCenter.value ??
        (controller.points.isNotEmpty ? controller.points.first.latLng : null);
    if (initial == null) {
      return const ColoredBox(
        color: Color(0xFFF2F4F8),
        child: Center(child: AppLoadingIndicator()),
      );
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: controller.mapController,
          options: MapOptions(
            initialCenter: initial,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
            onMapReady: controller.handleMapReady,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.amapTileUrl,
              subdomains: const ['1', '2', '3', '4'],
              userAgentPackageName: AppConfig.androidPackageName,
            ),
            Obx(() {
              final polylines = <Polyline>[];
              final played = controller.playedRoutePoints;
              if (played.length >= 2) {
                polylines.add(
                  Polyline(
                    points: played,
                    color: const Color(0xFF1890FF),
                    // 线宽与未播放的灰色虚线保持一致。
                    strokeWidth: 3,
                  ),
                );
              }
              final unplayed = controller.unplayedRoutePoints;
              if (unplayed.length >= 2) {
                polylines.add(
                  Polyline(
                    points: unplayed,
                    color: const Color(0xFF999999),
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: const [16, 8]),
                  ),
                );
              }
              return PolylineLayer(polylines: polylines);
            }),
            Obx(() {
              final markers = <Marker>[];
              if (controller.points.isNotEmpty) {
                markers.add(
                  Marker(
                    point: controller.points.first.latLng,
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/static/start.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                );
                markers.add(
                  Marker(
                    point: controller.points.last.latLng,
                    width: 24,
                    height: 24,
                    child: Image.asset(
                      'assets/static/end.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                );
              }
              final point = controller.currentPoint.value;
              if (point != null) {
                // 车标上方的速度/里程气泡：先加气泡再加车标，保证车标在上层。
                markers.add(
                  Marker(
                    point: point.latLng,
                    // 顶部对齐到车辆坐标：整个气泡框落在车标上方，不遮挡车标。
                    alignment: Alignment.topCenter,
                    width: 192,
                    height: 58,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _TrackInfoBubble(
                        speed: point.speed,
                        distanceKm: controller.playedDistanceMeters / 1000,
                      ),
                    ),
                  ),
                );
                markers.add(
                  Marker(
                    point: point.latLng,
                    width: 32,
                    height: 32,
                    child: Transform.rotate(
                      angle: point.rotation * pi / 180,
                      child: Image.asset(
                        deviceIconPath(
                          online: controller.device?.isOnline ?? false,
                          carType: controller.device?.carType,
                        ),
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              }
              return MarkerLayer(markers: markers);
            }),
          ],
        ),
        Obx(
          () => controller.isLoading.value
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CupertinoActivityIndicator(
                      radius: 12,
                      color: CupertinoColors.white,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// 底部播放面板：左侧竖长方形播放按钮，右侧两行等长拖动条
  /// 上「进度 + 提示百分比 + 里程」，下「倍速 + 倍速值」；
  /// 速度由地图车标气泡承载，底部避让 iOS 安全区。
  Widget _buildPanel(BuildContext context) {
    final playable = controller.isTrackPlayable.value;
    final progress = controller.playbackProgress.value
        .clamp(0.0, 1.0)
        .toDouble();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return MapBottomDrawer(
      expanded: controller.panelExpanded.value,
      onToggle: controller.togglePanel,
      onCollapse: controller.collapsePanel,
      backgroundColor: CupertinoColors.white,
      padding: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DateRangeCard(
            startTime: controller.startTime.value,
            endTime: controller.endTime.value,
            horizontal: true,
            showSeconds: false,
            onPickStart: () =>
                controller.pickDate(start: true, context: context),
            onPickEnd: () =>
                controller.pickDate(start: false, context: context),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左：竖长方形播放 / 暂停按钮。
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 62),
                onPressed: playable ? controller.togglePlayback : null,
                child: Container(
                  width: 44,
                  height: 62,
                  decoration: BoxDecoration(
                    color: playable
                        ? AppColors.primary
                        : CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: playable
                        ? const [
                            BoxShadow(
                              color: Color(0x263485DF),
                              blurRadius: 7,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    controller.isPlaying.value
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    color: CupertinoColors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 右：上进度（可拖动到任意位置续播），下倍速。
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          _SliderLabel(text: '进度'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RectThumbSlider(
                              value: progress,
                              onChangeStart: playable
                                  ? controller.beginSeek
                                  : null,
                              onChanged: playable ? controller.seekTo : null,
                              onChangeEnd: playable ? controller.endSeek : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 进度条右侧：总里程（已播放里程由车标气泡承载）。
                          _SliderValue(
                            text:
                                '${(controller.totalDistanceMeters / 1000).toStringAsFixed(1)} km',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          _SliderLabel(text: '倍速'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RectThumbSlider(
                              value: ((controller.playbackSpeed.value - 1) / 29)
                                  .clamp(0.0, 1.0),
                              divisions: 29,
                              onChanged: playable
                                  ? (value) =>
                                        controller.setSpeed(1 + value * 29)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SliderValue(
                            text:
                                '${controller.playbackSpeed.value.toStringAsFixed(0)}x',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 拖动条左侧固定宽度标签：两行标签同宽，保证滑块长度一致。
class _SliderLabel extends StatelessWidget {
  const _SliderLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        text,
        style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
      ),
    );
  }
}

/// 自定义滑条：矩形圆角拖块（CupertinoSlider 只有圆形拖块，无法定制形状）。
/// [value] 取值 0~1；[divisions] 传入时拖动值会吸附到等分档位（用于倍速取整）。
class _RectThumbSlider extends StatelessWidget {
  const _RectThumbSlider({
    required this.value,
    this.divisions,
    this.onChangeStart,
    this.onChanged,
    this.onChangeEnd,
  });

  final double value;
  final int? divisions;
  final VoidCallback? onChangeStart;
  final ValueChanged<double>? onChanged;
  final VoidCallback? onChangeEnd;

  void _apply(double dx, double width) {
    final callback = onChanged;
    if (callback == null || width <= 0) return;
    var ratio = (dx / width).clamp(0.0, 1.0);
    final divisions = this.divisions;
    if (divisions != null && divisions > 1) {
      ratio = (ratio * divisions).round() / divisions;
    }
    callback(ratio);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (details) {
                  onChangeStart?.call();
                  _apply(details.localPosition.dx, width);
                }
              : null,
          onTapUp: enabled ? (_) => onChangeEnd?.call() : null,
          onHorizontalDragStart: enabled ? (_) => onChangeStart?.call() : null,
          onHorizontalDragUpdate: enabled
              ? (details) => _apply(details.localPosition.dx, width)
              : null,
          onHorizontalDragEnd: enabled ? (_) => onChangeEnd?.call() : null,
          onHorizontalDragCancel: enabled ? () => onChangeEnd?.call() : null,
          child: CustomPaint(
            size: Size(width, 30),
            painter: _RectSliderPainter(
              value: value.clamp(0.0, 1.0),
              enabled: enabled,
            ),
          ),
        );
      },
    );
  }
}

/// 滑条绘制：3px 圆角轨道（灰）+ 已滑过部分（主题色）+ 矩形圆角拖块。
class _RectSliderPainter extends CustomPainter {
  _RectSliderPainter({required this.value, required this.enabled});

  final double value;
  final bool enabled;

  static const double _trackHeight = 3;
  static const double _thumbWidth = 12;
  static const double _thumbHeight = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const radius = Radius.circular(2);
    // 轨道。
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, centerY - _trackHeight / 2, size.width, _trackHeight),
        radius,
      ),
      Paint()..color = AppColors.divider,
    );
    // 已滑过部分。
    final activeWidth = size.width * value;
    if (activeWidth > 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            centerY - _trackHeight / 2,
            activeWidth,
            _trackHeight,
          ),
          radius,
        ),
        Paint()..color = AppColors.primary,
      );
    }
    // 矩形拖块。
    final thumbX = ((size.width - _thumbWidth) * value).clamp(
      0.0,
      size.width - _thumbWidth,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          thumbX,
          centerY - _thumbHeight / 2,
          _thumbWidth,
          _thumbHeight,
        ),
        const Radius.circular(4),
      ),
      Paint()
        ..color = enabled ? AppColors.primary : CupertinoColors.systemGrey4,
    );
  }

  @override
  bool shouldRepaint(_RectSliderPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.enabled != enabled;
}

/// 拖动条右侧固定宽度数值（右对齐）：两行同宽以对齐滑块右端。
class _SliderValue extends StatelessWidget {
  const _SliderValue({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 车标上方的信息气泡：与车辆跟踪页时速气泡同一套样式
///（白底圆角 + 描边阴影 + 向下小尖角）。
/// 内容 = 当前速度 + 已播放里程（原进度百分比换算后的里程）。
class _TrackInfoBubble extends StatelessWidget {
  const _TrackInfoBubble({required this.speed, required this.distanceKm});

  final double speed;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.speedometer,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${speed.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              Container(
                width: 1,
                height: 13,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: AppColors.divider,
              ),
              const Icon(
                CupertinoIcons.arrow_left_right,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const MapBubbleTail(),
      ],
    );
  }
}
