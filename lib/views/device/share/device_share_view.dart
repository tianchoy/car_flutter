import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/models/api_response.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'device_share_controller.dart';

class DeviceShareView extends GetView<DeviceShareController> {
  const DeviceShareView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '设备分享',
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(
        () => ReferencePage(
          child: controller.isLoading.value
              ? const Center(child: AppLoadingIndicator())
              : !controller.enabled.value
              ? EmptyState(
                  message: controller.errorMessage.value.isEmpty
                      ? '分享功能暂未开放，请稍后再试'
                      : controller.errorMessage.value,
                  icon: CupertinoIcons.share,
                )
              : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AppRefreshControl(
          onRefresh: () => controller.loadShares(reset: true),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildForm(context),
              SectionTitle('我发起的分享', action: '${controller.totalCount.value} 条'),
              const SizedBox(height: 8),
              if (controller.shares.isEmpty && !controller.isLoadingMore.value)
                ReferenceCard(
                  child: const EmptyState(
                    message: '暂无发起的分享',
                    icon: CupertinoIcons.person_2,
                  ),
                )
              else
                ...controller.shares.map(_buildShareCard),
              if (controller.isLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: AppLoadingIndicator()),
                )
              else if (controller.hasMore)
                CupertinoButton(
                  onPressed: controller.loadShares,
                  child: const Text('加载更多'),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final expire = controller.expireDate.value;
    return ReferenceCard(
      child: Column(
        children: [
          const SectionTitle('分享设备'),
          const SizedBox(height: 14),
          _readOnlyRow('设备', controller.deviceName),
          const SizedBox(height: 10),
          ReferenceTextField(
            controller: controller.targetPhoneController,
            placeholder: '请输入被分享者手机号',
            keyboardType: TextInputType.phone,
            maxLength: 11,
            textAlign: TextAlign.right,
            prefix: const Icon(CupertinoIcons.phone, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => controller.pickExpireDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expire == null ? '永久' : _formatDate(expire),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: CupertinoButton.filled(
              padding: EdgeInsets.zero,
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.createShare,
              child: controller.isSubmitting.value
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.share, color: CupertinoColors.white),
                        SizedBox(width: 8),
                        Text('确认分享'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.secondaryText)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '--' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(Map<String, dynamic> share) {
    final active = stringValue(share['status']) == 'active';
    return ReferenceCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.person, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.sharePerson(share),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusPill(label: controller.shareStatus(share), online: active),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: AppColors.divider),
          ),
          const SizedBox(height: 8),
          _detailRow('角色', stringValue(share['role'], fallback: 'view')),
          _detailRow('分享时间', controller.formatTime(share['shareTime'])),
          _detailRow(
            '到期时间',
            share['expireTime'] == null
                ? '永久'
                : controller.formatTime(share['expireTime']),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () => controller.showSharees(share),
                child: const Text('查看被分享者'),
              ),
              if (active)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () => controller.revokeShare(share),
                  child: const Text(
                    '撤销分享',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
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
              value.isEmpty ? '--' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
