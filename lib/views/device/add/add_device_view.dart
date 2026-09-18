import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'package:car/utils/car_icon.dart';
import 'add_device_controller.dart';

class AddDeviceView extends GetView<AddDeviceController> {
  const AddDeviceView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '添加设备',
      showBackButton: true,
      showBottomNavBar: false,
      body: ReferencePage(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ReferenceCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '设备信息',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // 设备名称非必填，无需监听错误状态，故不使用 Obx 包裹。
                  ReferenceInput(
                    controller: controller.nameController,
                    hint: '请输入设备名称（选填）',
                    prefix: const Icon(CupertinoIcons.tag),
                  ),
                  const SizedBox(height: 13),
                  Obx(
                    () => ReferenceInput(
                      controller: controller.deviceIdController,
                      hint: '请输入设备 ID / 设备号',
                      prefix: const Icon(CupertinoIcons.qrcode),
                      suffix: ReferenceIconButton(
                        onPressed: controller.scan,
                        icon: CupertinoIcons.camera_viewfinder,
                        color: AppColors.primary,
                        size: 21,
                      ),
                      errorText: controller.deviceIdError.value,
                    ),
                  ),
                  const SizedBox(height: 13),
                  ReferenceInput(
                    controller: controller.plateController,
                    hint: '请输入车牌号（选填）',
                    prefix: const Icon(CupertinoIcons.car),
                  ),
                  const SizedBox(height: 13),
                  Obx(
                    () => GestureDetector(
                      onTap: controller.openCarIconPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          // 与「设备 ID」输入框（ReferenceInput）保持完全一致的观感：
                          // 浅灰底 + 12 圆角，校验失败时边框标红。
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller.carTypeError.value.isNotEmpty
                                ? AppColors.danger
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.car_detailed,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                controller.selectedCarType.value.isEmpty
                                    ? '请选择设备图标'
                                    : carIconLabel(
                                        controller.selectedCarType.value,
                                      ),
                                style: TextStyle(
                                  color:
                                      controller.selectedCarType.value.isEmpty
                                      ? AppColors.secondaryText
                                      : AppColors.text,
                                ),
                              ),
                            ),
                            if (controller.selectedCarType.value.isNotEmpty)
                              Image.asset(
                                carIconPreviewPath(
                                  controller.selectedCarType.value,
                                ),
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => controller.carTypeError.value.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8, top: 6),
                            child: Text(
                              controller.carTypeError.value,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => ReferenceButton(
                label: '提交设备',
                icon: const Icon(CupertinoIcons.add),
                expand: true,
                loading: controller.isLoading.value,
                onPressed: controller.isLoading.value
                    ? null
                    : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
