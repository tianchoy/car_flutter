import 'package:flutter/widgets.dart';

import 'package:get/get.dart';

import 'package:car/app/route_arguments.dart';
import 'package:car/model/home/device_model.dart';
import 'package:car/shared/models/api_response.dart';
import 'package:car/shared/widgets/reference_date_time_picker.dart';
import 'package:car/model/vehicle/record_models.dart';
import 'stop_record_repository.dart';

class StopRecordController extends GetxController {
  StopRecordController({StopRecordRepository? repository})
    : _repository = repository ?? StopRecordRepository();

  final StopRecordRepository _repository;
  final DeviceModel? device = DeviceRouteArgs.deviceFrom(Get.arguments);
  final startTime = DateTime.now().subtract(const Duration(days: 1)).obs;
  final endTime = DateTime.now().obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final records = <StopRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final currentDevice = device;
    if (currentDevice == null) {
      errorMessage.value = '设备信息不存在';
      return;
    }
    if (endTime.value.isBefore(startTime.value)) {
      errorMessage.value = '结束时间不能早于开始时间';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.fetchTrack(<String, dynamic>{
        'deviceNo': currentDevice.deviceNo ?? currentDevice.deviceId,
        'startTime': _format(startTime.value),
        'endTime': _format(endTime.value),
        'minParkTime': 10,
        'withStop': true,
        'withPos': false,
        'withTrip': false,
      });
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        errorMessage.value = result.message.isEmpty ? '数据加载失败' : result.message;
        records.clear();
        return;
      }
      final rawRecords = result.data?['stops'];
      records.assignAll(
        rawRecords is List ? rawRecords.map(StopRecord.fromJson) : const [],
      );
      records.sort((a, b) => b.endTime.compareTo(a.endTime));
    } catch (_) {
      errorMessage.value = '数据加载失败，请稍后重试';
      records.clear();
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> pickDate({
    required bool start,
    required BuildContext context,
  }) async {
    final selected = await showReferenceDateTimePicker(
      context: context,
      initialDate: start ? startTime.value : endTime.value,
    );
    if (selected == null) return;
    if (start) {
      startTime.value = selected;
    } else {
      endTime.value = selected;
    }
    await load();
  }

  String _format(DateTime value) {
    String pad(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${pad(value.month)}-${pad(value.day)} '
        '${pad(value.hour)}:${pad(value.minute)}:${pad(value.second)}';
  }
}
