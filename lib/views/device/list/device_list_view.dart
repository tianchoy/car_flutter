import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/widgets/map_tile.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/app_bottom_sheet.dart';
import 'package:car/widgets/reference_ui.dart';
import 'device_list_controller.dart';
import 'package:car/utils/coord_transform.dart';
import 'package:car/utils/car_icon.dart';

class DeviceListView extends GetView<DeviceListController> {
  const DeviceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '全部设备',
      showBackButton: true,
      showBottomNavBar: false,
      actions: [
        Obx(
          () => ReferenceIconButton(
            icon: controller.showMap.value
                ? CupertinoIcons.list_bullet
                : CupertinoIcons.map,
            color: AppColors.text,
            onPressed: controller.toggleView,
          ),
        ),
        ReferenceIconButton(
          icon: CupertinoIcons.add,
          color: AppColors.text,
          onPressed: () => Get.toNamed(Routes.addDevice),
        ),
      ],
      body: Obx(
        () => ReferencePage(
          child: Column(
            children: [
              _buildStats(),
              Expanded(
                child: controller.showMap.value
                    ? _buildMap()
                    : _buildList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Obx(
          () => Row(
            children: [
              _filterTab('全部', controller.devices.length, AppColors.primary),
              _vDivider(),
              _filterTab('在线', controller.onlineCount, AppColors.success),
              _vDivider(),
              _filterTab('离线', controller.offlineCount, AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => const SizedBox(
    width: 1,
    height: 26,
    child: ColoredBox(color: AppColors.divider),
  );

  Widget _filterTab(String label, int value, Color color) {
    final selected = controller.filter.value == label;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => controller.filter.value = label,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .12) : null,
            borderRadius: selected ? BorderRadius.circular(10) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: selected ? color : AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final point = controller.mapCenter.value;
    final markers = controller.filteredDevices
        .where((device) => device.hasLocation)
        .map(
          (device) => Marker(
            width: 38,
            height: 38,
            point: transformToGCJ02(device.longitude!, device.latitude!),
            child: GestureDetector(
              onTap: () => controller.openDevice(device),
              child: Image.asset(
                deviceIconPath(
                  online: device.isOnline,
                  carType: device.carType,
                ),
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ReferenceCard(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MapTile(
            isLoading: controller.isLoading.value,
            errMsg: controller.devices.isEmpty ? '暂无设备定位' : '',
            latitude: point.latitude,
            longitude: point.longitude,
            initialZoom: 5,
            mapController: controller.mapController,
            clusterMarkers: true,
            fitToBounds: true,
            maxFitZoom: 7,
            markers: markers,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final devices = controller.filteredDevices;
    if (devices.isEmpty) return const EmptyState(message: '暂无设备');
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AppRefreshControl(onRefresh: controller.loadDevices),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          sliver: SliverList.separated(
            itemCount: devices.length,
            separatorBuilder: (_, index) => const SizedBox(height: 9),
            itemBuilder: (_, index) => _deviceCard(context, devices[index]),
          ),
        ),
      ],
    );
  }

  Widget _deviceCard(BuildContext context, DeviceModel device) {
    final isCurrent = device == controller.selectedDevice;
    final color = device.isOnline ? AppColors.success : AppColors.secondaryText;
    return ReferenceCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: const EdgeInsets.all(14),
        minimumSize: Size.zero,
        onPressed: () => controller.openDevice(device),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  deviceIconPath(
                    online: device.isOnline,
                    carType: device.carType,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.plateNo ?? device.deviceName ?? '未命名设备',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '设备号：${device.deviceNo ?? '--'}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isCurrent)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '当前',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      StatusPill(
                        label: device.isOnline ? '在线' : '离线',
                        online: device.isOnline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ReferenceIconButton(
              icon: CupertinoIcons.ellipsis,
              color: AppColors.secondaryText,
              onPressed: () => _showDeviceActions(context, device),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeviceActions(
    BuildContext context,
    DeviceModel device,
  ) async {
    final action = await showAppActionSheet<String>(
      context: context,
      title: device.plateNo ?? device.deviceName ?? '设备操作',
      actions: const [
        AppSheetAction<String>(label: '查看详情', value: 'detail'),
        AppSheetAction<String>(
          label: '解绑设备',
          value: 'unbind',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted) return;
    if (action == 'detail') controller.openDevice(device);
    if (action == 'unbind') controller.unbindDevice(context, device);
  }
}
