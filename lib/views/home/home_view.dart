import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';
import 'package:car/widgets/find_car.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes/route_arguments.dart';
import '../../app/routes/router_instance.dart';
import '../../services/app_links.dart';
import '../../utils/car_icon.dart';
import '../../utils/time_utils.dart';
import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_popup.dart';
import '../../widgets/map_marker_bubble.dart';
import '../../widgets/map_tile.dart';
import '../../models/home/device_model.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/reference_ui.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '首页',
      showBackButton: false,
      showBottomNavBar: true,
      actions: [
        SizedBox(
          width: 88,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _topNavAction(
                icon: CupertinoIcons.globe,
                onPressed: () {
                  if (!_requireLogin()) return;
                  Get.toNamed(Routes.deviceList);
                },
              ),
              _topNavAction(
                icon: CupertinoIcons.add_circled,
                onPressed: () {
                  if (!_requireLogin()) return;
                  Get.toNamed(Routes.addDevice);
                },
              ),
            ],
          ),
        ),
      ],
      // 刷新/加载的反馈统一由 AppRefreshControl 展示（与消息页保持一致）：
      // 不再叠加页面级居中 loading 指示器，也不再出现半透明遮罩层。
      body: Obx(() => _buildHomeContent(context)),
    );
  }

  Widget _topNavAction({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Icon(icon, size: 22),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final device = controller.selectedDevice.value;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (controller.isLoggedIn.value)
          AppRefreshControl(onRefresh: controller.loadDeviceList),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildDeviceHeader(context, device),
              _buildInfoCard(device),
              _buildLocationCard(),
              _buildTrackCard(device),
              _buildServiceCard(context),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceHeader(BuildContext context, DeviceModel? device) {
    final isLoggedIn = controller.isLoggedIn.value;
    final title = isLoggedIn
        ? (device?.deviceName?.isNotEmpty == true
              ? device!.deviceName!
              : device?.plateNo?.isNotEmpty == true
              ? device!.plateNo!
              : device?.deviceNo?.isNotEmpty == true
              ? device!.deviceNo!
              : '暂无设备')
        : '点击登录';
    return ReferenceCard(
      padding: EdgeInsets.fromLTRB(16, 12, isLoggedIn ? 8 : 16, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                deviceIconPath(
                  online: device?.isOnline ?? false,
                  carType: device?.carType,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: !isLoggedIn
                  ? () => Get.toNamed(Routes.login)
                  : controller.deviceList.length < 2
                  ? null
                  : () => _showDevicePicker(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoggedIn) ...[
                    const Text(
                      '当前车辆',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Row(
                    children: [
                      // 用 Flexible（松约束）而非 Expanded（紧约束）：
                      // 文字按实际内容宽度收缩，下拉箭头才会紧跟在设备名称右侧 5px，
                      // 而不是被撑满剩余宽度后顶到最右边。
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLoggedIn && controller.deviceList.length > 1) ...[
                        // 下拉箭头与设备名称保持 5px 间距。
                        const SizedBox(width: 5),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 15,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoggedIn)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: controller.refreshAll,
              child: const Icon(
                CupertinoIcons.refresh_circled,
                color: AppColors.primary,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDevicePicker(BuildContext context) async {
    final devices = controller.deviceList;
    if (devices.isEmpty) return;
    final device = await AppPopup.show<DeviceModel>(
      context: context,
      title: '选择车辆',
      options: devices,
      displayText: _deviceDisplayName,
      isShowMessage: false,
      selectedOption: controller.selectedDevice.value,
      trailingBuilder: _deviceStatusTrailing,
    );
    if (device != null) controller.selectDevice(device);
  }

  String _deviceDisplayName(DeviceModel device) {
    final name = (device.deviceName ?? '').trim();
    if (name.isNotEmpty) return name;
    final plate = (device.plateNo ?? '').trim();
    if (plate.isNotEmpty) return plate;
    return device.deviceNo ?? device.deviceId;
  }

  /// 设备选择弹框右侧的在线/离线状态标识。
  Widget _deviceStatusTrailing(DeviceModel device) {
    final online = device.isOnline;
    final statusColor = online ? AppColors.success : AppColors.secondaryText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
        ),
        const SizedBox(width: 6),
        Text(
          online ? '在线' : '离线',
          style: TextStyle(fontSize: 13, color: statusColor),
        ),
      ],
    );
  }

  Future<void> _startFindCarForDevice(
    BuildContext context,
    DeviceModel? device,
    LatLng? destination,
  ) async {
    if (destination == null) {
      AppToast.show('提示', '设备暂无有效定位');
      return;
    }
    await startFindCar(
      context,
      destination: destination,
      title:
          device?.plateNo ?? device?.deviceName ?? device?.deviceNo ?? '我的车辆',
    );
  }

  Widget _buildInfoCard(DeviceModel? device) {
    final detail = controller.deviceDetail.value;
    final battery = (detail?.status.batteryPercent ?? 0)
        .clamp(0, 100)
        .toDouble();
    // 选中设备离线时，即使详情数据尚未刷新，也不能显示为在线。
    final online = device?.isOnline == true && detail?.isOnline != false;
    // 未登录、暂无设备或设备离线时，定位相关数据统一以设备状态的深灰色展示。
    final hasOnlineDevice =
        controller.isLoggedIn.value && device != null && online;
    final inactiveColor = AppColors.secondaryText;
    // 最后定位：优先用定位点自带的上报时间，其次用设备详情的最后更新时间。
    // 设备离线后坐标不再变化，必须按真实上报时间算相对时间，不能兜底成「刚刚」。
    final positionTime = controller.devicePositionTime.value;
    final lastLoc = relativeTime(
      positionTime.isNotEmpty ? positionTime : detail?.lastUpdateTime,
      fallback: controller.devicePosition.value == null ? '暂无位置' : '暂无定位时间',
    );
    return ReferenceCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: _infoItem(
              CupertinoIcons.battery_full,
              '电量',
              '${battery.toStringAsFixed(0)}%',
              hasOnlineDevice ? AppColors.success : inactiveColor,
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: _infoItem(
              CupertinoIcons.bolt_fill,
              '电压',
              '${(detail?.status.voltage ?? 0).toStringAsFixed(1)}V',
              hasOnlineDevice ? AppColors.warning : inactiveColor,
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: _infoItem(
              CupertinoIcons.wifi,
              '设备状态',
              online ? '在线' : '离线',
              online ? AppColors.success : inactiveColor,
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: _infoItem(
              CupertinoIcons.time,
              '最后定位',
              lastLoc,
              hasOnlineDevice ? AppColors.primary : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 5),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final device = controller.selectedDevice.value;
    final isLoggedIn = controller.isLoggedIn.value;
    final hasDeviceMarker =
        isLoggedIn && device != null && controller.devicePosition.value != null;
    final shouldShowUserLocation = !isLoggedIn || device == null;
    // 未登录或暂无设备时展示手机当前位置；已登录且有设备时只展示车辆位置。
    final point = hasDeviceMarker
        ? controller.devicePosition.value!
        : (shouldShowUserLocation && controller.hasUserLocation.value
              ? controller.currentPosition.value
              : null);
    return ReferenceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // 与其他模块统一：标题距卡片顶 16、标题与内容间距 10。
          // 「刷新位置」改用 SectionTitle 的 action，与「更多轨迹」共用同一套
          // 样式与最小尺寸，避免手写按钮的默认最小高度把标题行撑高。
          Padding(
            // 标题与地图之间的间距收紧（10 → 6）。
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: SectionTitle(
              '车辆定位',
              action: '刷新位置',
              onTap: () {
                if (!_requireLogin()) return;
                controller.refreshLocation();
              },
            ),
          ),
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: point == null
                  ? const ColoredBox(
                      color: Color(0xFFF2F4F8),
                      child: Center(child: AppLoadingIndicator()),
                    )
                  : MapTile(
                      // 刷新反馈统一由 AppRefreshControl 展示（与消息页一致），
                      // 此处不再叠加地图内的第二个指示器。
                      isLoading: false,
                      errMsg: _positionMessage(),
                      latitude: point.latitude,
                      longitude: point.longitude,
                      mapController: controller.mapController,
                      initialZoom: 15,
                      clusterMarkers: false,
                      markers: [
                        Marker(
                          // 定位点与车标中心重合；名称气泡只向上延伸，
                          // 不再因整个标记以底部为锚点而把车标顶偏。
                          width: 144,
                          height: 88,
                          alignment: Alignment.center,
                          point: point,
                          child: hasDeviceMarker
                              ? _deviceLocationMarker(device)
                              : _myLocationMarker(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(DeviceModel? device) {
    final summary = controller.trackSummary.value;
    return ReferenceCard(
      child: Column(
        children: [
          SectionTitle(
            '轨迹记录',
            action: '更多轨迹',
            onTap: () {
              if (!_requireLogin()) return;
              if (device == null) {
                AppToast.show('提示', '暂无可查看的设备');
                return;
              }
              Get.toNamed(
                Routes.playback,
                arguments: PlaybackRouteArgs(
                  device,
                  startTime: _todayStart(),
                  endTime: DateTime.now(),
                  // 带上已获取的原始坐标：回放页首帧即可居中到车辆位置。
                  latitude: controller.deviceRawPosition.value?.latitude,
                  longitude: controller.deviceRawPosition.value?.longitude,
                ),
              );
            },
          ),
          // 与「服务中心」模块保持一致：标题与内容间距 10。
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _trackMetric(
                  icon: CupertinoIcons.location,
                  value: '${summary.tripCount}',
                  unit: '条',
                  label: '今日轨迹',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _trackMetric(
                  icon: CupertinoIcons.speedometer,
                  value: (summary.totalDistanceMeters / 1000).toStringAsFixed(
                    1,
                  ),
                  unit: 'km',
                  label: '今日里程',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackMetric({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
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
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 当天 0 点，作为首页轨迹记录「更多轨迹」进入播放页的时间起点。
  DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 服务中心：四宫格（设备详情 / 在线客服 / 一键寻车 / 删除设备）。
  Widget _buildServiceCard(BuildContext context) {
    final device = controller.selectedDevice.value;
    return ReferenceCard(
      child: Column(
        children: [
          const SectionTitle('服务中心'),
          const SizedBox(height: 10),
          FeatureGrid(
            crossAxisCount: 4,
            children: [
              FeatureTile(
                icon: CupertinoIcons.car_detailed,
                assetName: 'car',
                title: '设备详情',
                onTap: () {
                  if (!_requireLogin()) return;
                  if (device == null) {
                    AppToast.show('提示', '暂无可查看的设备');
                    return;
                  }
                  Get.toNamed(
                    Routes.detail,
                    arguments: DeviceRouteArgs(
                      device,
                      // 带上已获取的原始坐标：详情页首帧即可居中到车辆位置。
                      latitude: controller.deviceRawPosition.value?.latitude,
                      longitude: controller.deviceRawPosition.value?.longitude,
                    ),
                  );
                },
              ),
              FeatureTile(
                icon: CupertinoIcons.chat_bubble_2,
                assetName: 'msg',
                title: '在线客服',
                color: AppColors.primary,
                onTap: () {
                  if (!_requireLogin()) return;
                  LegalLinks.showCustomerService(context);
                },
              ),
              FeatureTile(
                icon: CupertinoIcons.location,
                assetName: 'pos',
                title: '一键寻车',
                color: AppColors.success,
                onTap: () {
                  if (!_requireLogin()) return;
                  _startFindCarForDevice(
                    context,
                    device,
                    controller.devicePosition.value,
                  );
                },
              ),
              FeatureTile(
                icon: CupertinoIcons.delete,
                assetName: 'del',
                title: '删除设备',
                color: AppColors.danger,
                onTap: () {
                  if (!_requireLogin()) return;
                  _confirmDeleteDevice(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDevice(BuildContext context) async {
    final device = controller.selectedDevice.value;
    if (device == null) {
      AppToast.show('提示', '暂无可操作的设备');
      return;
    }
    final name = device.deviceName?.isNotEmpty == true
        ? device.deviceName!
        : device.plateNo ?? device.deviceId;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: '删除设备',
      message: '确定删除“$name”吗？删除后不可恢复。',
      confirmLabel: '删除',
      isDestructive: true,
    );
    if (confirmed == true) await controller.deleteDevice(device);
  }

  bool _requireLogin() {
    if (controller.isLoggedIn.value) return true;
    AppToast.show('提示', '请去登录');
    return false;
  }

  String _positionMessage() {
    // 未登录或暂无设备时地图展示用户当前位置，不显示车辆定位错误。
    if (!controller.isLoggedIn.value ||
        controller.selectedDevice.value == null) {
      return '';
    }
    switch (controller.positionState.value) {
      case 'empty':
        return '暂无车辆定位数据';
      case 'invalid':
        return '定位数据异常';
      case 'failed':
        return '位置获取失败，请重试';
      default:
        return controller.errorMessage.value;
    }
  }

  /// 未登录或暂无设备时，地图中心展示的小尺寸用户当前位置图钉。
  Widget _myLocationMarker() => _mapMarker(
    label: '您的位置',
    icon: const Icon(
      CupertinoIcons.location_solid,
      color: CupertinoColors.systemBlue,
      size: 24,
    ),
  );

  Widget _deviceLocationMarker(DeviceModel device) => _mapMarker(
    label: _deviceLocationLabel(device),
    icon: Image.asset(
      deviceIconPath(online: device.isOnline, carType: device.carType),
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    ),
  );

  String _deviceLocationLabel(DeviceModel device) {
    for (final value in [device.deviceName, device.plateNo, device.deviceNo]) {
      final label = value?.trim() ?? '';
      if (label.isNotEmpty) return label;
    }
    return '当前设备';
  }

  Widget _mapMarker({required String label, required Widget icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 128),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1A000000)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const MapBubbleTail(),
        icon,
      ],
    );
  }
}
