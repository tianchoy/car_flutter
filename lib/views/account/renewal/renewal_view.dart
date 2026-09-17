import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
import 'renewal_controller.dart';

class RenewalView extends GetView<RenewalController> {
  const RenewalView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '平台续费',
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
                  itemBuilder: (_, index) =>
                      _renewalCard(controller.devices[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _renewalCard(dynamic device) {
    return ReferenceCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.device_phone_portrait,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  device.deviceName?.isNotEmpty == true
                      ? device.deviceName!
                      : device.plateNo ?? '未命名设备',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusPill(
                label: device.isOnline ? '在线' : '离线',
                online: device.isOnline,
              ),
            ],
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: AppColors.divider),
          ),
          const SizedBox(height: 15),
          if (device.iccid?.isNotEmpty == true) _row('ICCID', device.iccid!),
          _row('设备号', device.deviceNo ?? device.deviceId),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ReferenceButton(
              label: '去续费',
              filled: false,
              onPressed: () => controller.startRenewal(device),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
