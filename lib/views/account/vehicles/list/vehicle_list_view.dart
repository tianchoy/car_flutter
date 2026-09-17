import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
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
          icon: CupertinoIcons.add,
          color: AppColors.text,
          onPressed: controller.openAddDevice,
        ),
      ],
      body: Obx(
        () => CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppRefreshControl(
              onRefresh: () => controller.load(reset: true),
            ),
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

  Widget _deviceCard(dynamic device) {
    final online = device.isOnline;
    final color = online ? AppColors.success : AppColors.primary;
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
              child: Icon(CupertinoIcons.car_detailed, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName?.isNotEmpty == true
                        ? device.deviceName!
                        : device.plateNo ?? '未命名车辆',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (device.plateNo?.isNotEmpty == true) device.plateNo!,
                      'ID：${device.deviceId}',
                      if (device.deviceNo?.isNotEmpty == true)
                        '设备号：${device.deviceNo}',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
