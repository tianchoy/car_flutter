import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/models/home/device_model.dart';
import 'package:car/utils/car_icon.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'vehicle_list_controller.dart';

class VehicleListView extends GetView<VehicleListController> {
  const VehicleListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '我的车辆',
      showBackButton: true,
      showBottomNavBar: false,
      actions: [
        ReferenceIconButton(
          icon: CupertinoIcons.add_circled,
          color: AppColors.text,
          onPressed: controller.openAddDevice,
        ),
      ],
      body: Obx(
        () => CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppRefreshControl(onRefresh: () => controller.load(reset: true)),
            if (controller.devices.isEmpty && controller.isLoading.value)
              const SliverFillRemaining(
                child: Center(child: AppLoadingIndicator()),
              )
            else if (controller.devices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  message: controller.errorMessage.value.isEmpty
                      ? '暂无车辆设备'
                      : controller.errorMessage.value,
                  icon: CupertinoIcons.car_detailed,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                sliver: SliverList.separated(
                  itemCount: controller.devices.length + 1,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    if (index == controller.devices.length) {
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Center(
                          child: controller.isLoading.value
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  controller.hasMore.value
                                      ? '上拉加载更多'
                                      : '没有更多车辆了',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      );
                    }
                    return _deviceCard(controller.devices[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(DeviceModel device) {
    final online = device.isOnline;
    final color = online ? AppColors.success : AppColors.primary;
    final title = device.deviceName?.isNotEmpty == true
        ? device.deviceName!
        : device.plateNo ?? '未命名车辆';
    final plate = device.plateNo?.isNotEmpty == true
        ? device.plateNo!
        : '未设置车牌';
    final deviceNumber = device.deviceNo?.isNotEmpty == true
        ? device.deviceNo!
        : 'ID：${device.deviceId}';

    return ReferenceCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: Size.zero,
        onPressed: () => controller.openDevice(device),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                deviceIconPath(online: online, carType: device.carType),
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 34,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _subtitleRow(label: '车牌', value: plate),
                        _subtitleRow(label: '设备', value: deviceNumber),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subtitleRow({required String label, required String value}) {
    return SizedBox(
      height: 16,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
