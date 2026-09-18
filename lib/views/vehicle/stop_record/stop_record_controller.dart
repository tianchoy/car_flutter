import 'package:flutter/widgets.dart';

import 'package:get/get.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/reference_date_time_picker.dart';
import 'package:car/widgets/app_toast.dart';
import 'package:car/models/vehicle/record_models.dart';
import 'stop_record_repository.dart';
import 'package:car/utils/time_utils.dart';

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
  /// 正在解析中文地址的记录 key（避免重复点击、用于显示「解析中…」）。
  final parsingKeys = <String>{}.obs;

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
        'startTime': formatDateTime(startTime.value),
        'endTime': formatDateTime(endTime.value),
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

  /// 记录唯一 key：用于定位列表中的条目与去重。
  String _keyOf(StopRecord record) => '${record.startTime}|${record.endTime}';

  bool isParsing(StopRecord record) => parsingKeys.contains(_keyOf(record));

  /// 解析某条停车记录的中文地址（与「设备详情」用的是同一个逆地理接口）。
  /// 成功后把结果写回该条记录，列表中直接展示中文地址。
  Future<void> parseAddress(StopRecord record) async {
    final latitude = record.latitude;
    final longitude = record.longitude;
    if (latitude == null || longitude == null) {
      AppToast.show('提示', '该记录无经纬度，无法解析');
      return;
    }
    final key = _keyOf(record);
    if (parsingKeys.contains(key)) return;
    parsingKeys.add(key);
    parsingKeys.refresh();
    try {
      final value = await _repository.fetchAddress(<String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'deviceId': device?.deviceId ?? '',
        if (device?.deviceNo != null && device!.deviceNo!.isNotEmpty)
          'deviceNo': device!.deviceNo,
      });
      if (isClosed) return;
      final index = records.indexWhere((item) => _keyOf(item) == key);
      if (index < 0) return;
      final text = (value ?? '').trim();
      if (text.isEmpty) {
        AppToast.show('提示', '未解析到中文地址');
        return;
      }
      records[index] = records[index].copyWith(address: text);
      records.refresh();
    } catch (_) {
      if (!isClosed) AppToast.show('提示', '解析失败，请稍后重试');
    } finally {
      parsingKeys.remove(key);
      parsingKeys.refresh();
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

}
