import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/car_icon_picker.dart';
import 'package:car/views/account/scan_code/scan_code_controller.dart';
import 'add_device_repository.dart';

/// 提交前规整设备 ID：与 Web 端扫码回填规则一致（15 位纯数字去掉前 4 位后
/// 左补一个 0、11 位纯数字左补一个 0，规整后为 12 位），其余原样提交。
String _normalizeDeviceId(String raw) {
  return ScanCodeController.standardizeDeviceId(raw.trim());
}

class AddDeviceController extends GetxController {
  AddDeviceController({AddDeviceRepository? repository})
    : _repository = repository ?? AddDeviceRepository();

  final AddDeviceRepository _repository;
  final nameController = TextEditingController();
  final deviceIdController = TextEditingController();
  final plateController = TextEditingController();
  final nameError = ''.obs;
  final deviceIdError = ''.obs;
  final carTypeError = ''.obs;
  final selectedCarType = ''.obs;
  final isLoading = false.obs;

  /// 设备名称非必填：留空不标红、不拦截提交。
  void validateName(String value) {
    nameError.value = '';
  }

  void validateDeviceId(String value) {
    deviceIdError.value = value.trim().isEmpty ? '请输入设备 ID / 设备号' : '';
  }

  void validateCarType() {
    carTypeError.value = selectedCarType.value.isEmpty ? '请选择设备图标' : '';
  }

  Future<void> scan() async {
    // 扫码前先确保相机权限，避免打开扫码页后相机无法启动。
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!status.isGranted) {
      AppToast.show('提示', '需要相机权限才能扫码，请在系统设置中开启');
      return;
    }
    // 不能用 Get.toNamed<String>：GetX 会把路由强转为 Route<String>，
    // 而注册的 GetPageRoute 是 dynamic，会抛类型异常导致点击无反应。
    final result = await Get.toNamed(Routes.scanCode);
    if (result is String && result.trim().isNotEmpty) {
      deviceIdController.text = result.trim();
      deviceIdError.value = '';
    }
  }

  Future<void> submit() async {
    validateName(nameController.text);
    validateDeviceId(deviceIdController.text);
    validateCarType();
    // 必填项为「设备 ID / 设备号」与「设备图标」，设备名称可留空。
    if (isLoading.value ||
        deviceIdError.value.isNotEmpty ||
        carTypeError.value.isNotEmpty) {
      return;
    }
    isLoading.value = true;
    try {
      final name = nameController.text.trim();
      // 提交时规整设备 ID（与 Web 端规则一致，见 _normalizeDeviceId）。
      final deviceId = _normalizeDeviceId(deviceIdController.text);
      print('deviceId: $deviceId');
      final response = await _repository.addDevice(<String, dynamic>{
        // 名称非必填：留空时不提交该字段，避免后端校验空字符串而报错。
        if (name.isNotEmpty) 'deviceName': name,
        'deviceId': deviceId,
        'deviceNo': deviceId,
        'carType': selectedCarType.value,
        if (plateController.text.trim().isNotEmpty)
          'plateNo': plateController.text.trim(),
      });
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        AppToast.show('成功', '设备添加成功');
        Get.offNamed(Routes.deviceList);
      } else {
        AppToast.show('提示', result.message.isEmpty ? '添加设备失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '添加设备失败，请稍后重试');
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// 从底部弹出车标选择网格，选中后写入 [selectedCarType]。
  Future<void> openCarIconPicker() async {
    final context = Get.context;
    if (context == null) return;
    final picked = await showCarIconPicker(
      context: context,
      current: selectedCarType.value,
      crossAxisCount: 5,
    );
    if (picked != null) {
      selectedCarType.value = picked;
      carTypeError.value = '';
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    deviceIdController.dispose();
    plateController.dispose();
    super.onClose();
  }
}
