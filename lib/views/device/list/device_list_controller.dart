import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:car/shared/widgets/app_toast.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/app/router_instance.dart';
import 'package:car/model/home/device_model.dart';
import 'package:car/shared/models/api_response.dart';
import 'package:car/views/home/home_controller.dart';
import 'package:car/utils/CoordTransform.dart';
import 'device_list_repository.dart';

class DeviceListController extends GetxController {
  DeviceListController({DeviceListRepository? repository})
    : _repository = repository ?? DeviceListRepository();

  final DeviceListRepository _repository;
  final MapController mapController = MapController();
  final devices = <DeviceModel>[].obs;
  final showMap = true.obs;
  final filter = '全部'.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final mapCenter = const LatLng(39.9042, 116.4074).obs;

  int get onlineCount => devices.where((device) => device.isOnline).length;
  int get offlineCount => devices.length - onlineCount;

  /// 当前首页选中的设备（来自 HomeController，跨页面共享），用于在列表中高亮「当前」设备。
  DeviceModel? get selectedDevice =>
      Get.isRegistered<HomeController>()
          ? Get.find<HomeController>().selectedDevice.value
          : null;
  List<DeviceModel> get filteredDevices {
    if (filter.value == '在线') {
      return devices.where((device) => device.isOnline).toList();
    }
    if (filter.value == '离线') {
      return devices.where((device) => !device.isOnline).toList();
    }
    return devices.toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadDevices();
  }

  void toggleView() => showMap.toggle();

  Future<void> loadDevices() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.fetchDevices();
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        errorMessage.value = result.message.isEmpty
            ? '获取设备列表失败'
            : result.message;
        devices.clear();
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final list = data['list'] is List
          ? data['list'] as List
          : data['rows'] is List
          ? data['rows'] as List
          : const [];
      devices.assignAll(
        list
            .whereType<Map>()
            .map((item) => DeviceModel.fromJson(jsonMapFrom(item)))
            .where((device) => device.deviceId.isNotEmpty),
      );
      final first = devices.firstWhereOrNull((device) => device.hasLocation);
      if (first != null) {
        mapCenter.value = transformToGCJ02(first.longitude!, first.latitude!);
      }
    } catch (_) {
      errorMessage.value = '获取设备列表失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void openDevice(DeviceModel device) =>
      Get.toNamed(Routes.detail, arguments: device);

  Future<void> unbindDevice(BuildContext context, DeviceModel device) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('解绑设备'),
        content: Text(
          '确定解绑“${device.plateNo ?? device.deviceName ?? device.deviceId}”吗？',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('解绑'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await _repository.deleteDevice(device.deviceId);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        await loadDevices();
      } else {
        AppToast.show('提示', result.message.isEmpty ? '解绑失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '解绑设备失败，请稍后重试');
    }
  }
}
