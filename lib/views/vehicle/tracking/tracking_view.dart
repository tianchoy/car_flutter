import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/widgets/map_marker_bubble.dart';
import 'package:car/widgets/map_tile.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'tracking_controller.dart';

class TrackingView extends GetView<TrackingController> {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '车辆跟踪',
      showBackButton: true,
      showBottomNavBar: false,
      body: ReferencePage(
        child: Stack(
          children: [
            Positioned.fill(child: _buildMap()),
            // 与地理围栏 / 设备详情 / 轨迹回放保持一致：地图顶部浮动显示
            // 设备名称 + 在线状态。
            Obx(
              () => Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: MapTitleBar(
                  icon: CupertinoIcons.car_detailed,
                  title: controller.device?.deviceName?.isNotEmpty == true
                      ? controller.device!.deviceName!
                      : controller.device?.plateNo?.isNotEmpty == true
                      ? controller.device!.plateNo!
                      : controller.device?.deviceNo ?? '当前车辆',
                  statusLabel: controller.isOnline ? '在线' : '离线',
                  statusOnline: controller.isOnline,
                ),
              ),
            ),
            // 开始/停止跟踪改为地图上的悬浮按钮（底部面板已移除）。
            _buildTrackingFab(),
          ],
        ),
      ),
    );
  }

  /// 悬浮在地图右下角的跟踪开关：不再占用底部面板，地图可视区域最大化。
  Widget _buildTrackingFab() {
    return Obx(() {
      final tracking = controller.isTracking.value;
      final disabled = controller.isLoading.value;
      return Positioned(
        right: 16,
        // 留出底部安全区（iOS Home Indicator）高度，避免被系统横线压住。
        bottom: 28,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            minimumSize: Size.zero,
            borderRadius: BorderRadius.circular(24),
            color: tracking ? AppColors.danger : AppColors.primary,
            onPressed: disabled ? null : controller.toggleTracking,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tracking
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.play_fill,
                  size: 17,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  tracking ? '停止跟踪' : '开始跟踪',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMap() {
    return Obx(() {
      // 还没有任何可用坐标（首次进入且无缓存）：显示占位加载，
      // 而不是先用默认坐标（北京）构建地图、等接口返回再跳过去。
      final point =
          controller.currentPosition.value ?? controller.initialCenter.value;
      if (point == null) {
        return ColoredBox(
          color: const Color(0xFFF2F4F8),
          child: Center(
            child: controller.isLoading.value
                ? const AppLoadingIndicator()
                : const EmptyState(
                    message: '暂无车辆位置',
                    icon: CupertinoIcons.location,
                  ),
          ),
        );
      }
      return MapTile(
        isLoading: controller.isLoading.value,
        errMsg: controller.errorMessage.value,
        latitude: point.latitude,
        longitude: point.longitude,
        initialZoom: 15,
        mapController: controller.mapController,
        clusterMarkers: false,
        markers: _mapMarkers(point),
        polylines: _routePolylines,
      );
    });
  }

  /// 车标 + 车标上方的时速气泡（底部面板移除后，时速改由地图气泡承载）。
  List<Marker> _mapMarkers(LatLng point) {
    final carMarkers = controller.markers;
    // 车标尚未就绪（只有缓存中心）时不画气泡，避免气泡悬空。
    if (carMarkers.isEmpty) return carMarkers;
    return <Marker>[
      ...carMarkers,
      Marker(
        point: point,
        // 顶部对齐到车辆坐标：整个气泡框落在车标上方，不遮挡车标。
        alignment: Alignment.topCenter,
        width: 140,
        height: 54,
        child: Align(
          alignment: Alignment.topCenter,
          child: _SpeedBubble(speed: controller.speed.value),
        ),
      ),
    ];
  }

  /// 与轨迹播放保持一致：已行驶=蓝色实线，未行驶=淡灰色虚线。
  List<Polyline> get _routePolylines {
    final polylines = <Polyline>[];
    final traveled = controller.traveledRoutePoints;
    if (traveled.length >= 2) {
      polylines.add(
        Polyline(
          points: traveled,
          color: const Color(0xFF1890FF),
          strokeWidth: 6,
        ),
      );
    }
    final untraveled = controller.untraveledRoutePoints;
    if (untraveled.length >= 2) {
      polylines.add(
        Polyline(
          points: untraveled,
          color: const Color(0xFF999999),
          strokeWidth: 3,
          pattern: StrokePattern.dashed(segments: const [16, 8]),
        ),
      );
    }
    return polylines;
  }
}

/// 车标上方的时速气泡：白底圆角 + 向下的小尖角，指向车标。
class _SpeedBubble extends StatelessWidget {
  const _SpeedBubble({required this.speed});

  final double speed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
            ],
          ),
        ),
        const MapBubbleTail(),
      ],
    );
  }
}
