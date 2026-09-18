import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/services/url.dart';
import 'package:car/widgets/main_scaffold.dart';
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
            Column(
              children: [
                // The map is built ONCE (outside Obx) so the tile layer and
                // camera stay stable; only the marker/polyline layers update
                // per frame via inner Obx. Rebuilding the whole FlutterMap every
                // frame is what made the car appear to jump instantly.
                // 用 Obx 包裹：无坐标时显示占位，坐标就绪后再构建地图
                // （FlutterMap 仍只构建一次，不会每帧重建）。
                Expanded(child: Obx(() => _buildMap())),
                Obx(() => _buildPanel(context)),
              ],
            ),
            _buildTopBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final device = controller.device;
    final plate = <String?>[
      device?.deviceName,
      device?.plateNo,
      device?.deviceNo,
      device?.deviceId,
    ].firstWhere(
      (value) => value != null && value.trim().isNotEmpty,
      orElse: () => null,
    ) ?? '未命名设备';
    final status = controller.device?.deviceStatus ?? '';
    final online = status.toLowerCase() == 'online';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.car_detailed,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  plate,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (online ? AppColors.success : AppColors.secondaryText)
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: online
                            ? AppColors.success
                            : AppColors.secondaryText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      online ? '在线' : '离线',
                      style: TextStyle(
                        color: online
                            ? AppColors.success
                            : AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
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
