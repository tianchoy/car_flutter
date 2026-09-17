import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'vehicle_list_repository.dart';

class VehicleListController extends GetxController {
  VehicleListController({VehicleListRepository? repository})
    : _repository = repository ?? VehicleListRepository();

  final VehicleListRepository _repository;
  final scrollController = ScrollController();
  final devices = <DeviceModel>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    load(reset: true);
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 180) {
      load();
    }
  }

  Future<void> load({bool reset = false}) async {
    if (isLoading.value || (!reset && !hasMore.value)) return;
    if (reset) {
      _page = 1;
      hasMore.value = true;
      devices.clear();
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.fetchDevices(page: _page);
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        errorMessage.value = result.message.isEmpty
            ? '获取车辆列表失败'
            : result.message;
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final raw = data['list'] is List
          ? data['list'] as List
          : data['rows'] is List
          ? data['rows'] as List
          : const <dynamic>[];
      final loaded = raw
          .whereType<Map>()
          .map((item) => DeviceModel.fromJson(jsonMapFrom(item)))
          .where((item) => item.deviceId.isNotEmpty)
          .toList();
      final totalPage = intValue(
        data['totalPage'] ?? data['pages'],
        fallback: loaded.length < 10 ? _page : _page + 1,
      );
      devices.addAll(loaded);
      hasMore.value = _page < totalPage && loaded.isNotEmpty;
      if (hasMore.value) _page++;
    } catch (_) {
      errorMessage.value = '获取车辆列表失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void openAddDevice() async {
    await Get.toNamed(Routes.addDevice);
    await load(reset: true);
  }

  void openDevice(DeviceModel device) =>
      Get.toNamed(Routes.vehicleDetail, arguments: device);

  @override
  void onClose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.onClose();
  }
}
