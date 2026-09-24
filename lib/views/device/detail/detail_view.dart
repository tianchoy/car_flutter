import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/app/routes/route_observer.dart';
import 'package:car/app/routes/router_instance.dart';
import 'package:car/widgets/map_tile.dart';
import 'package:car/utils/car_icon.dart';
import 'package:car/models/home/device_detail_model.dart';
import 'package:car/widgets/app_toast.dart';
import 'package:car/widgets/find_car.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/app_bottom_sheet.dart';
import 'package:car/widgets/app_confirm_dialog.dart';
import 'package:car/widgets/reference_ui.dart';
import 'detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainScaffold(
          title: '详情',
          showBackButton: true,
          showBottomNavBar: false,
          actions: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showRefreshOptions(context),
              child: const Icon(CupertinoIcons.timer, size: 20),
            ),
          ],
          body: Obx(
            () => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                AppRefreshControl(onRefresh: controller.loadDetails),
                SliverPadding(
                  // 顶部留白为 0：让地图卡片紧贴顶部导航栏；底部收紧，iOS 安全区已占空间。
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMapCard(),
                      _buildDeviceInfoCard(),
                      // 设备状态放在「展示 ID」模块下方
                      if (controller.detail.value != null)
                        _buildStatusCard(controller.detail.value!),
                      _buildFeatureCard(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        _RouteAwarePause(controller: controller),
      ],
    );
  }

  Future<void> _showRefreshOptions(BuildContext context) async {
    final selected = await showAppActionSheet<int>(
      context: context,
      title: '刷新频率',
      actions: [
        _refreshAction(5, '每 5 秒刷新'),
        _refreshAction(10, '每 10 秒刷新'),
        _refreshAction(30, '每 30 秒刷新'),
        _refreshAction(0, '停止刷新'),
      ],
    );
    if (selected == null) return;
    controller.setRefreshInterval(selected);
  }

  AppSheetAction<int> _refreshAction(int seconds, String label) =>
      AppSheetAction<int>(
        label: label,
        value: seconds,
        // 以「实际生效的刷新间隔」比对：设备离线时定时器不运行，选中项应为「停止刷新」。
        isDefault: controller.selectedRefreshIntervalSeconds == seconds,
      );

  Widget _buildMapCard() {
    // 接口返回前先用缓存位置（无缓存时才回退默认坐标），避免地图先落在北京。
    final point = controller.mapPosition ?? controller.initialCenter.value;
    final title = controller.device?.deviceName?.isNotEmpty == true
        ? controller.device!.deviceName!
        : controller.device?.plateNo?.isNotEmpty == true
        ? controller.device!.plateNo!
        : controller.device?.deviceNo?.isNotEmpty == true
        ? controller.device!.deviceNo!
        : '当前车辆';
    return ReferenceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 278,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    // 还没有任何可用坐标时显示占位加载，而不是先用默认坐标
                    // （北京）构建地图、等到接口返回再跳过去。
                    child: point == null
                        ? _buildMapPlaceholder()
                        : MapTile(
                            latitude: point.latitude,
                            longitude: point.longitude,
                            mapController: controller.mapController,
                            onMapReady: controller.handleMapReady,
                            initialZoom: 15,
                            clusterMarkers: false,
                            isLoading: controller.isRefreshing.value,
                            errMsg: controller.errorMessage.value,
                            markers: [
                              Marker(
                                width: 32,
                                height: 32,
                                point: point,
                                child: Image.asset(
                                  deviceIconPath(
                                    online: controller.isOnline,
                                    carType: controller.device?.carType,
                                  ),
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: MapTitleBar(
                      icon: CupertinoIcons.car_detailed,
                      title: title,
                      statusLabel: controller.isOnline ? '在线' : '离线',
                      statusOnline: controller.isOnline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.location,
                  color: AppColors.primary,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '地址：${controller.isLoadingAddress.value ? '正在解析…' : controller.displayAddress}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (controller.isLoadingAddress.value ||
                    controller.showParseAddressButton)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: controller.parseAddress,
                      child: Text(
                        controller.isLoadingAddress.value ? '解析中…' : '解析中文地址',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
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

  /// 还没有可用坐标时的占位：加载中显示指示器，加载完成仍无坐标则提示无定位，
  /// 避免先渲染默认坐标（北京）再跳到真实位置。
  Widget _buildMapPlaceholder() {
    if (controller.isLoading.value) {
      return const ColoredBox(
        color: Color(0xFFF2F4F8),
        child: Center(child: AppLoadingIndicator()),
      );
    }
    return const ColoredBox(
      color: Color(0xFFF2F4F8),
      child: EmptyState(message: '设备暂无有效定位', icon: CupertinoIcons.location),
    );
  }

  Widget _buildDeviceInfoCard() {
    final device = controller.device;
    return ReferenceCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 22,
                child: Center(
                  child: Transform.translate(
                    offset: defaultTargetPlatform == TargetPlatform.android
                        ? const Offset(0, -3)
                        : Offset.zero,
                    child: const Icon(
                      CupertinoIcons.device_phone_portrait,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'ID：${device?.deviceNo ?? device?.deviceId ?? '--'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              // ID 右侧直接展示当前选中的自动刷新频率（右上角定时器图标可切换）。
              Text(
                controller.refreshIntervalLabel,
                style: TextStyle(
                  color: controller.isAutoRefreshEnabled
                      ? AppColors.success
                      : AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 通信时间靠左、定位时间靠右，同一行两端对齐。
          Row(
            children: [
              Expanded(child: _infoItem('通信时间', controller.communicationTime)),
              const SizedBox(width: 16),
              Expanded(
                child: _infoItem(
                  '定位时间',
                  controller.locationTime,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, {bool alignRight = false}) =>
      Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );

  Widget _buildStatusCard(DeviceDetailModel detail) {
    final hasOnlineDevice = controller.isOnline;
    final inactiveColor = AppColors.secondaryText;
    return ReferenceCard(
      child: Column(
        children: [
          const SectionTitle('设备状态'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final item in [
                (
                  CupertinoIcons.wifi,
                  '信号',
                  controller.signalStrength,
                  hasOnlineDevice ? AppColors.success : inactiveColor,
                ),
                (
                  CupertinoIcons.antenna_radiowaves_left_right,
                  '卫星',
                  controller.satelliteCount,
                  hasOnlineDevice ? AppColors.primaryDark : inactiveColor,
                ),
                (
                  CupertinoIcons.bolt_fill,
                  '电压',
                  '${controller.voltage}V',
                  hasOnlineDevice ? AppColors.warning : inactiveColor,
                ),
                (
                  CupertinoIcons.battery_full,
                  '电量',
                  '${controller.batteryPercent}%',
                  hasOnlineDevice ? AppColors.success : inactiveColor,
                ),
              ])
                Flexible(
                  fit: FlexFit.loose,
                  child: _statusItem(item.$1, item.$2, item.$3, item.$4),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label, String value, Color color) =>
      Row(
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
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildFeatureCard(BuildContext context) => ReferenceCard(
    child: Column(
      children: [
        const SectionTitle('车辆功能'),
        FeatureGrid(
          crossAxisCount: 5,
          children: [
            _feature(
              CupertinoIcons.chart_bar_alt_fill,
              '轨迹回放',
              Routes.playback,
              assetName: 'gjhf',
            ),
            _feature(
              CupertinoIcons.location,
              '车辆跟踪',
              Routes.tracking,
              assetName: 'clgz',
              color: AppColors.success,
            ),
            _feature(
              CupertinoIcons.arrow_right,
              '里程记录',
              Routes.mileage,
              assetName: 'lcjl',
              color: AppColors.primaryDark,
            ),
            _feature(
              CupertinoIcons.car_detailed,
              '停车记录',
              Routes.stopRecord,
              assetName: 'tcjl',
              color: AppColors.warning,
            ),
            _feature(
              CupertinoIcons.square_grid_2x2,
              '电子围栏',
              Routes.geofence,
              assetName: 'dzwl',
              color: const Color(0xFF6E58B5),
            ),
            FeatureTile(
              icon: CupertinoIcons.search,
              assetName: 'pos',
              title: '一键寻车',
              color: AppColors.primary,
              onTap: () {
                final dest = controller.mapPosition;
                if (dest == null) {
                  AppToast.show('提示', '设备暂无有效定位');
                  return;
                }
                final context = Get.context;
                if (context == null) return;
                final device = controller.device;
                startFindCar(
                  context,
                  destination: dest,
                  title:
                      device?.plateNo ??
                      device?.deviceName ??
                      device?.deviceNo ??
                      '我的车辆',
                );
              },
            ),
            FeatureTile(
              icon: CupertinoIcons.power,
              assetName: 'power',
              title: '恢复油电',
              color: AppColors.success,
              onTap: () => _sendPowerCommand(restore: true, context: context),
            ),
            FeatureTile(
              icon: CupertinoIcons.xmark_octagon,
              assetName: 'offpower',
              title: '断开油电',
              color: AppColors.danger,
              onTap: () => _sendPowerCommand(restore: false, context: context),
            ),
            _feature(
              CupertinoIcons.paperplane,
              '发送指令',
              Routes.commands,
              assetName: 'cmd',
              color: AppColors.danger,
            ),
            _feature(
              CupertinoIcons.share,
              '分享设备',
              Routes.deviceShare,
              assetName: 'share',
              color: const Color(0xFF159A9C),
            ),
          ],
        ),
      ],
    ),
  );

  /// 断油电 / 恢复油电：确认后调用控制器下发指令。
  ///
  /// 只做「提示 + 确定 / 取消」：之前在弹框内嵌密码输入框，iOS 上键盘弹起会与
  /// 弹框布局反复相互触发，偶发整屏卡死（重新打包后首次运行尤为明显）。
  Future<void> _sendPowerCommand({
    required bool restore,
    required BuildContext context,
  }) async {
    final confirmed = await showAppConfirmDialog(
      // 用页面自身的 context：Get.context 指向根 Navigator，
      // 根 Navigator 与当前页路由栈不一致时弹框会挂到错误的栈上。
      context: context,
      title: restore ? '恢复油电' : '断开油电',
      message: restore ? '确定恢复车辆油电吗？' : '确定断开车辆油电吗？',
    );
    if (confirmed != true || !context.mounted) return;
    await controller.sendPowerCommand(restore: restore);
  }

  Widget _feature(
    IconData icon,
    String title,
    String route, {
    required String assetName,
    Color? color,
  }) => FeatureTile(
    icon: icon,
    assetName: assetName,
    title: title,
    color: color ?? AppColors.primary,
    onTap: controller.device == null
        ? null
        : () => Get.toNamed(
            route,
            arguments: DeviceRouteArgs(
              controller.device!,
              // 带上本页已获取的原始坐标：下游页面首帧即可居中到车辆位置。
              latitude: controller.rawPosition?.latitude,
              longitude: controller.rawPosition?.longitude,
            ),
          ),
  );
}

/// 通过 [RouteAware] 监听详情页进出栈：离开本页暂停自动刷新，返回本页恢复。
class _RouteAwarePause extends StatefulWidget {
  const _RouteAwarePause({required this.controller});

  final DetailController controller;

  @override
  State<_RouteAwarePause> createState() => _RouteAwarePauseState();
}

class _RouteAwarePauseState extends State<_RouteAwarePause> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() => widget.controller.pauseAutoRefresh();

  @override
  void didPopNext() => widget.controller.resumeAutoRefresh();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
