import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/app_toast.dart';
import 'package:car/services/session_expiry_coordinator.dart';
import 'vehicle_detail_repository.dart';

class VehicleDetailController extends GetxController {
  VehicleDetailController({VehicleDetailRepository? repository})
    : _repository = repository ?? VehicleDetailRepository();

  final VehicleDetailRepository _repository;
  final additionalInfo = <String, dynamic>{}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isEditing = false.obs;
  final errorMessage = ''.obs;
  final nameController = TextEditingController();
  final plateController = TextEditingController();

  /// 当前选中的车标（carType），编辑态下可更改。
  final carType = ''.obs;

  DeviceModel? get device {
    final argument = Get.arguments;
    if (argument is DeviceModel) return argument;
    if (argument is Map) {
      return DeviceModel.fromJson(
        argument.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    final current = device;
    nameController.text = current?.deviceName ?? '';
    plateController.text = current?.plateNo ?? '';
    carType.value = current?.carType ?? '';
    load();
  }

  /// 进入 / 退出编辑；退出时还原为原始数据。
  void toggleEdit() {
    if (isEditing.value) {
      final current = device;
      nameController.text = current?.deviceName ?? '';
      plateController.text = current?.plateNo ?? '';
      carType.value = current?.carType ?? '';
    }
    isEditing.value = !isEditing.value;
  }

  /// 保存车辆信息（名称与车牌号）。
  Future<void> save() async {
    final current = device;
    if (current == null || current.deviceId.isEmpty) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show('提示', '请输入车辆名称');
      return;
    }
    isSaving.value = true;
    final plate = plateController.text.trim();
    try {
      final payload = <String, dynamic>{
        'deviceId': current.deviceId,
        'deviceName': name,
        'plateNo': plate,
        if (carType.value.isNotEmpty) 'carType': carType.value,
      };
      final response = await _repository.updateDevice(payload);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isTokenExpired) {
        await SessionExpiryCoordinator.handleExpiredSession();
        return;
      }
      if (!result.isSuccess) {
        AppToast.show('提示', result.message.isEmpty ? '保存失败' : result.message);
        return;
      }
      current.deviceName = name;
      current.plateNo = plate;
      current.carType = carType.value.isEmpty ? null : carType.value;
      isEditing.value = false;
      AppToast.show('提示', '保存成功');
    } catch (_) {
      AppToast.show('提示', '保存失败，请稍后重试');
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    plateController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final current = device;
    if (current == null || current.deviceId.isEmpty || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.fetchDeviceInfo(current.deviceId);
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isTokenExpired) {
        await SessionExpiryCoordinator.handleExpiredSession();
        return;
      }
      if (result.isSuccess) {
        additionalInfo.assignAll(result.data ?? const <String, dynamic>{});
      } else {
        errorMessage.value = result.message.isEmpty
            ? '获取车辆详情失败'
            : result.message;
      }
    } catch (_) {
      errorMessage.value = '获取车辆详情失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  String value(List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = additionalInfo[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '--') return value;
    }
    return fallback;
  }
}
