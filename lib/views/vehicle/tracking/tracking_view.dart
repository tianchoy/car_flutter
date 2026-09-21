import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

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
            Column(
              children: [
                Expanded(child: _buildMap()),
                _buildToolsPanel(),
              ],
            ),
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
          ],
        ),
      ),
    );
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
        markers: controller.markers,
        polylines: _routePolylines,
      );
    });
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

  /// 底部面板仅展示时速、定位时间与跟踪开关；设备名称和在线状态已在地图顶部展示。
  Widget _buildToolsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部小横条：与地理围栏的底部弹层一致，让面板更像「可拉起的抽屉」。
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: CupertinoIcons.speedometer,
                    label: '时速',
                    value: '${controller.speed.value.toStringAsFixed(1)} km/h',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoItem(
                    icon: CupertinoIcons.time,
                    label: '定位时间',
                    value: controller.positionTime.value.isEmpty
                        ? '暂无'
                        : controller.positionTime.value,
                    valueFontSize: 11,
                    fitValueToSingleLine: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 44,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                color: controller.isTracking.value
                    ? AppColors.danger
                    : AppColors.primary,
                onPressed: controller.isLoading.value
                    ? null
                    : controller.toggleTracking,
                child: Text(
                  controller.isTracking.value ? '停止跟踪' : '开始跟踪',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueFontSize = 13,
    this.fitValueToSingleLine = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final double valueFontSize;
  final bool fitValueToSingleLine;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      maxLines: fitValueToSingleLine ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: valueFontSize,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                if (fitValueToSingleLine)
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: valueText,
                    ),
                  )
                else
                  valueText,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
