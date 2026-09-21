import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/services/url.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/map_bottom_drawer.dart';
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
                    strokeWidth: 6,
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
                markers.add(
                  Marker(
                    point: point.latLng,
                    width: 38,
                    height: 38,
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

  /// 底部播放面板：与地理围栏共用 MapBottomDrawer，
  /// 向上弹出 / 向下收起，两个方向动画时长一致。
  Widget _buildPanel(BuildContext context) {
    return MapBottomDrawer(
      expanded: controller.panelExpanded.value,
      onToggle: controller.togglePanel,
      // 下滑用幂等收起，避免一次手势反复切换。
      onCollapse: controller.collapsePanel,
      backgroundColor: CupertinoColors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DateRangeCard(
            startTime: controller.startTime.value,
            endTime: controller.endTime.value,
            horizontal: true,
            showSeconds: true,
            onPickStart: () =>
                controller.pickDate(start: true, context: context),
            onPickEnd: () =>
                controller.pickDate(start: false, context: context),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: !controller.isTrackPlayable.value
                    ? CupertinoColors.systemGrey4
                    : AppColors.primary.withValues(alpha: .12),
                onPressed: !controller.isTrackPlayable.value
                    ? null
                    : controller.togglePlayback,
                child: Icon(
                  controller.isPlaying.value
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: !controller.isTrackPlayable.value
                      ? CupertinoColors.systemGrey
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoSlider(
                  value: controller.playbackSpeed.value,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: controller.setSpeed,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1890FF)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${controller.playbackSpeed.value.toStringAsFixed(0)}x',
                  style: const TextStyle(
                    color: Color(0xFF1890FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.page,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric(
                  '时间',
                  controller.currentTimeStr.value.isEmpty
                      ? '--'
                      : controller.currentTimeStr.value,
                ),
                _metric(
                  '速度',
                  '${controller.currentSpeed.value.toStringAsFixed(0)}Km/h',
                ),
                _metric(
                  '里程',
                  '${(controller.totalDistanceMeters / 1000).toStringAsFixed(1)}Km',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),
      ],
    );
  }
}
