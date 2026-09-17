import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
import 'package:car/components/widget/car_icon_picker.dart';
import 'package:car/utils/car_icon.dart';
import 'vehicle_detail_controller.dart';

class VehicleDetailView extends GetView<VehicleDetailController> {
  const VehicleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '车辆详情',
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(() {
        final current = controller.device;
        if (current == null) {
          return const EmptyState(
            message: '未获取到车辆信息',
            icon: CupertinoIcons.exclamationmark_triangle,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            ReferenceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.car_detailed,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          current.deviceName?.isNotEmpty == true
                              ? current.deviceName!
                              : current.plateNo ?? '未命名车辆',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: current.isOnline ? '在线' : '离线',
                        online: current.isOnline,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 1,
                    child: ColoredBox(color: AppColors.divider),
                  ),
                  const SizedBox(height: 16),
                  // 编辑态下名称、车牌、车标可修改，其余字段只读。
                  if (controller.isEditing.value) ...[
                    _field('车辆名称', controller.nameController),
                    const SizedBox(height: 10),
                    _field('车牌号', controller.plateController),
                    const SizedBox(height: 16),
                    _iconRow(),
                    const SizedBox(height: 8),
                  ] else ...[
                    _row('车牌号', current.plateNo ?? '--'),
                    // 车标：名称 + 当前车标 icon
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 76,
                            child: Text(
                              '车标',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  controller.carType.value.isEmpty
                                      ? '默认'
                                      : carIconLabel(controller.carType.value),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(width: 6),
                                Image.asset(
                                  carIconPreviewPath(
                                    controller.carType.value.isEmpty
                                        ? 'default'
                                        : controller.carType.value,
                                  ),
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _row('设备 ID', current.deviceId),
                  _row('设备号', current.deviceNo ?? '--'),
                  _row('ICCID', current.iccid ?? '--'),
                  _row('设备类型', current.deviceType ?? '--'),
                  _row('更新时间', controller.value(['lastUpdateTime'])),
                ],
              ),
            ),
            if (controller.errorMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 12),
            if (controller.isEditing.value) ...[
              ReferenceButton(
                label: '保存车辆信息',
                icon: controller.isSaving.value
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Icon(CupertinoIcons.check_mark),
                loading: controller.isSaving.value,
                expand: true,
                onPressed: controller.save,
              ),
              const SizedBox(height: 8),
              ReferenceButton(
                label: '取消',
                filled: false,
                expand: true,
                onPressed: controller.toggleEdit,
              ),
            ] else
              ReferenceButton(
                label: '编辑车辆信息',
                icon: const Icon(CupertinoIcons.pencil),
                expand: true,
                onPressed: controller.toggleEdit,
              ),
          ],
        );
      }),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController fieldController) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ),
        Expanded(
          child: CupertinoTextField(
            controller: fieldController,
            textAlign: TextAlign.right,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            placeholder: '请输入$label',
            placeholderStyle: const TextStyle(
              color: CupertinoColors.placeholderText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconRow() {
    final selected = controller.carType.value;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: _showIconPicker,
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              '车标',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  selected.isEmpty ? '默认' : carIconLabel(selected),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Image.asset(
                  carIconPreviewPath(selected.isEmpty ? 'default' : selected),
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 15,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showIconPicker() async {
    final rootContext = Get.context;
    if (rootContext == null) return;
    final picked = await showCarIconPicker(
      context: rootContext,
      current: controller.carType.value,
      crossAxisCount: 5,
    );
    if (picked != null) controller.carType.value = picked;
  }
}
