import 'package:flutter/widgets.dart';

import 'package:get/get.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/reference_date_time_picker.dart';
import 'mileage_repository.dart';
import 'package:car/models/vehicle/record_models.dart';
import 'package:car/utils/time_utils.dart';

class MileageController extends GetxController {
  MileageController({MileageRepository? repository})
    : _repository = repository ?? MileageRepository();

  final MileageRepository _repository;
  final DeviceModel? device = DeviceRouteArgs.deviceFrom(Get.arguments);
  final startTime = DateTime.now().subtract(const Duration(days: 1)).obs;
  final endTime = DateTime.now().obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final trips = <TrackTrip>[].obs;

  double get totalDistanceMeters =>
      trips.fold(0, (total, trip) => total + trip.distanceMeters);
  double get averageSpeed => trips.isEmpty
      ? 0
      : trips.fold(0.0, (total, trip) => total + trip.averageSpeed) /
            trips.length;

  List<MileageTripGroup> get groups {
    final grouped = <String, List<TrackTrip>>{};
    for (final trip in trips) {
      final date = _datePart(trip.startTime);
      grouped.putIfAbsent(date, () => []).add(trip);
    }
    final result = grouped.entries
        .map(
          (entry) => MileageTripGroup(
            date: entry.key,
            trips: entry.value,
            totalDistanceMeters: entry.value.fold(
              0,
              (total, trip) => total + trip.distanceMeters,
            ),
          ),
        )
        .toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

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
      final response = await _repository.fetchTrack(_query(currentDevice));
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        errorMessage.value = result.message.isEmpty ? '数据加载失败' : result.message;
        trips.clear();
        return;
      }
      final rawTrips = result.data?['trips'];
      trips.assignAll(
        rawTrips is List ? rawTrips.map(TrackTrip.fromJson) : const [],
      );
      trips.sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (_) {
      errorMessage.value = '数据加载失败，请稍后重试';
      trips.clear();
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

  Map<String, dynamic> _query(DeviceModel currentDevice) => <String, dynamic>{
    'deviceNo': currentDevice.deviceNo ?? currentDevice.deviceId,
    'startTime': formatDateTime(startTime.value),
    'endTime': formatDateTime(endTime.value),
    'minParkTime': 120,
    'withStop': false,
    'withPos': false,
    'withTrip': true,
  };

  String _datePart(String value) => value.split(' ').first;
}
