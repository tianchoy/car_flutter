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
import '../../widgets/app_popup.dart';
import '../../widgets/map_tile.dart';
import '../../models/home/device_model.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/reference_ui.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy =
          controller.isLoading.value ||
          controller.isLoadingDetails.value ||
          controller.isRefreshingPosition.value;
      return MainScaffold(
        title: '首页',
        showBackButton: false,
        showBottomNavBar: true,
        // 刷新（加载）过程中整页禁止点击，避免用户在加载期间操作其他控件。
        busy: busy,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => Get.toNamed(Routes.deviceList),
            child: const Icon(CupertinoIcons.globe, size: 19),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () => Get.toNamed(Routes.addDevice),
            child: const Icon(CupertinoIcons.add_circled, size: 19),
          ),
        ],
        body: Stack(
          children: [
            _buildHomeContent(context),
            if (busy)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x0A000000),
                    child: Center(child: AppLoadingIndicator()),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHomeContent(BuildContext context) {
    final device = controller.selectedDevice.value;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AppRefreshControl(onRefresh: controller.loadDeviceList),
        SliverPadding(
          // 服务中心为页面最后一个模块，需与底部导航栏保留一段可见间距，
          // 避免模块底部紧贴/被导航栏「吃掉」空白。
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildDeviceHeader(context, device),
              _buildInfoCard(device),
              _buildLocationCard(),
              _buildTrackCard(device),
              _buildFeatureCard(context, device),
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
        : '暂未登录';
    return ReferenceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                  const Text(
                    '当前车辆',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
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
    final online = detail?.isOnline == true || device?.isOnline == true;
    // 最后定位：按接口返回的最后更新时间做相对展示
    // （刚刚 / x分钟前 / x小时前 / x天前 / x个月前 / x年前）；
    // 接口没给时间但有定位时才兜底为「刚刚」。
    final lastLoc = relativeTime(
      detail?.lastUpdateTime,
      fallback: controller.devicePosition.value == null ? '暂无位置' : '刚刚',
    );
    return ReferenceCard(
      child: Row(
        // 四项信息两端对齐铺满卡片宽度，避免左右两侧出现过大留白。
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoItem(
            CupertinoIcons.battery_full,
            '电量',
            '${battery.toStringAsFixed(0)}%',
            AppColors.success,
          ),
          _infoItem(
            CupertinoIcons.bolt_fill,
            '电压',
            '${(detail?.status.voltage ?? 0).toStringAsFixed(1)}V',
            AppColors.warning,
          ),
          _infoItem(
            CupertinoIcons.wifi,
            '设备状态',
            online ? '在线' : '离线',
            online ? AppColors.success : AppColors.secondaryText,
          ),
          _infoItem(CupertinoIcons.time, '最后定位', lastLoc, AppColors.primary),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildLocationCard() {
    final device = controller.selectedDevice.value;
    final hasDeviceMarker =
        device != null && controller.devicePosition.value != null;
    // 有设备：仅展示选中设备的位置；暂无设备：展示用户当前位置（带 marker）。
    final point = hasDeviceMarker
        ? controller.devicePosition.value!
        : controller.currentPosition.value;
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
              onTap: controller.refreshAll,
            ),
          ),
          SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: MapTile(
                // 刷新位置时的加载提示统一由页面级居中指示器展示（busy 已包含
                // isRefreshingPosition），此处不再叠加地图内的第二个指示器，
                // 避免刷新时页面中央同时出现两个 loading。
                isLoading: false,
                errMsg: _positionMessage(),
                latitude: point.latitude,
                longitude: point.longitude,
                mapController: controller.mapController,
                initialZoom: 14,
                clusterMarkers: false,
                markers: [
                  Marker(
                    width: 36,
                    height: 36,
                    point: point,
                    child: hasDeviceMarker
                        ? Image.asset(
                            deviceIconPath(
                              online: device.isOnline,
                              carType: device.carType,
                            ),
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          )
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
            onTap: device == null
                ? () => AppToast.show('提示', '暂无可查看的设备')
                : () => Get.toNamed(
                    Routes.playback,
                    arguments: PlaybackRouteArgs(
                      device,
                      startTime: _todayStart(),
                      endTime: DateTime.now(),
                    ),
                  ),
          ),
          // 与「设备详情」「服务中心」模块保持一致：标题与内容间距 10。
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MetricRing(
                value: '${summary.tripCount}',
                unit: '条',
                label: '今日轨迹',
                color: AppColors.primary,
              ),
              MetricRing(
                value: (summary.totalDistanceMeters / 1000).toStringAsFixed(1),
                unit: 'km',
                label: '今日里程',
                color: AppColors.warning,
              ),
            ],
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

  Widget _buildFeatureCard(BuildContext context, DeviceModel? device) {
    return ReferenceCard(
      child: Column(
        children: [
          const SectionTitle('设备详情'),
          const SizedBox(height: 10),
          FeatureGrid(
            crossAxisCount: 4,
            children: [
              FeatureTile(
                icon: CupertinoIcons.car_detailed,
                assetName: 'car',
                title: '设备详情',
                onTap: device == null
                    ? () => AppToast.show('提示', '暂无可查看的设备')
                    : () => Get.toNamed(
                        Routes.detail,
                        arguments: DeviceRouteArgs(device),
                      ),
              ),
              FeatureTile(
                icon: CupertinoIcons.chart_bar_alt_fill,
                assetName: 'gjhf',
                title: '轨迹回放',
                color: AppColors.primaryDark,
                onTap: device == null
                    ? null
                    : () => Get.toNamed(
                        Routes.playback,
                        arguments: DeviceRouteArgs(device),
                      ),
              ),
              FeatureTile(
                icon: CupertinoIcons.location,
                assetName: 'pos',
                title: '一键寻车',
                color: AppColors.success,
                onTap: () => _startFindCarForDevice(
                  context,
                  controller.selectedDevice.value,
                  controller.devicePosition.value,
                ),
              ),
              FeatureTile(
                icon: CupertinoIcons.layers_alt,
                assetName: 'dzwl',
                title: '电子围栏',
                color: const Color(0xFF6E58B5),
                onTap: device == null
                    ? null
                    : () => Get.toNamed(
                        Routes.geofence,
                        arguments: DeviceRouteArgs(device),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context) {
    return ReferenceCard(
      child: Column(
        children: [
          const SectionTitle('服务中心'),
          const SizedBox(height: 10),
          FeatureGrid(
            crossAxisCount: 3,
            children: [
              FeatureTile(
                icon: CupertinoIcons.refresh_thick,
                assetName: 'pay',
                title: '一键续费',
                color: AppColors.warning,
                onTap: () => Get.toNamed(Routes.renewal),
              ),
              FeatureTile(
                icon: CupertinoIcons.chat_bubble_2,
                assetName: 'msg',
                title: '在线客服',
                color: AppColors.primary,
                onTap: () => LegalLinks.showCustomerService(context),
              ),
              FeatureTile(
                icon: CupertinoIcons.delete,
                assetName: 'del',
                title: '删除设备',
                color: AppColors.danger,
                onTap: () => _confirmDeleteDevice(context),
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除设备'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('确定删除“$name”吗？删除后不可恢复。'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteDevice(device);
  }

  String _positionMessage() {
    // 暂无设备时地图展示用户当前位置（含 marker），不再提示「暂无车辆定位数据」。
    if (controller.selectedDevice.value == null) return '';
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

  /// 暂无设备时，地图中心展示的用户当前位置标记（蓝点 + 定位图标）。
  Widget _myLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withValues(alpha: .25),
        shape: BoxShape.circle,
        border: Border.all(color: CupertinoColors.systemBlue, width: 2),
      ),
      child: const Icon(
        CupertinoIcons.location_fill,
        color: CupertinoColors.systemBlue,
        size: 18,
      ),
    );
  }
}
