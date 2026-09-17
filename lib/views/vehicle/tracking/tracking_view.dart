import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/components/widget/map_tile.dart';
import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
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
        child: Column(
          children: [
            Expanded(child: _buildMap()),
            _buildToolsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Obx(() {
      final point =
          controller.currentPosition.value ?? const LatLng(39.9042, 116.4074);
      return MapTile(
        isLoading: controller.isLoading.value,
        errMsg: controller.errorMessage.value,
        latitude: point.latitude,
        longitude: point.longitude,
        initialZoom: 15,
        mapController: controller.mapController,
        clusterMarkers: false,
        markers: controller.markers,
        polylines: controller.routePoints.length > 1
            ? [
                Polyline(
                  points: controller.routePoints.toList(),
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
              ]
            : const <Polyline>[],
      );
    });
  }

  Widget _buildToolsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _vehicleTitle()),
              Obx(
                () => CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.toggleTracking,
                  child: Text(controller.isTracking.value ? '停止跟踪' : '开始跟踪'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                // 时速内容较短，按需占位；定位时间较长，占用剩余宽度以保证完整显示。
                Flexible(
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
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Row(
              children: [
                StatusPill(
                  label: controller.isOnline ? '在线' : '离线',
                  online: controller.isOnline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.address.value.isEmpty
                        ? '暂无地址信息'
                        : controller.address.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleTitle() {
    final device = controller.device;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          device?.plateNo ?? device?.deviceName ?? device?.deviceNo ?? '当前车辆',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          device?.deviceNo ?? device?.deviceId ?? '设备信息未知',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                // 允许折行并略微缩小字号，保证定位时间等长文本完整显示。
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
