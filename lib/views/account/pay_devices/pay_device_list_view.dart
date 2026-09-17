import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'pay_device_list_controller.dart';

class PayDeviceListView extends GetView<PayDeviceListController> {
  const PayDeviceListView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '设备续费',
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(
        () => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppRefreshControl(onRefresh: controller.load),
            if (controller.isLoading.value)
              const SliverFillRemaining(
                child: Center(child: AppLoadingIndicator()),
              )
            else if (controller.devices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  message: controller.errorMessage.value.isEmpty
                      ? '暂无设备数据'
                      : controller.errorMessage.value,
                  icon: CupertinoIcons.device_phone_portrait,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                sliver: SliverList.separated(
                  itemCount: controller.devices.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final device = controller.devices[index];
                    return ReferenceCard(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(16),
                        minimumSize: Size.zero,
                        onPressed: () => controller.startRenewal(device),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.device_phone_portrait,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.deviceName?.isNotEmpty == true
                                        ? device.deviceName!
                                        : device.plateNo ?? '未命名设备',
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    device.deviceNo ?? device.deviceId,
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
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
