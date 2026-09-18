import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/models/home/device_model.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
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
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _hero(),
                    const SizedBox(height: 14),
                    for (final device in controller.devices) ...[
                      _renewalCard(device),
                      const SizedBox(height: 10),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 顶部说明头图：渐变背景 + 设备数徽标，说明续费用途。
  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2874C7),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.refresh_circled_solid,
              color: CupertinoColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '为设备服务续期',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '及时续费，保障定位与轨迹服务不中断',
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: .82),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Obx(
              () => Text(
                '${controller.devices.length} 台设备',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renewalCard(DeviceModel device) {
    final title = device.deviceName?.isNotEmpty == true
        ? device.deviceName!
        : device.plateNo ?? '未命名设备';
    final subtitle = device.plateNo?.isNotEmpty == true &&
            device.deviceName?.isNotEmpty == true
        ? device.plateNo
        : null;

    return ReferenceCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.device_phone_portrait,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  label: device.isOnline ? '在线' : '离线',
                  online: device.isOnline,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13),
            child: SizedBox(
              width: double.infinity,
              height: 1,
              child: ColoredBox(color: AppColors.divider),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (device.iccid?.isNotEmpty == true)
                  _row('ICCID', device.iccid!),
                _row('设备号', device.deviceNo ?? device.deviceId),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    minimumSize: Size.zero,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () => controller.startRenewal(device),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '去续费',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.arrow_right,
                          color: CupertinoColors.white,
                          size: 14,
                        ),
                      ],
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
