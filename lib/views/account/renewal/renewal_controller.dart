import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'renewal_repository.dart';

class RenewalController extends GetxController {
  RenewalController({RenewalRepository? repository})
    : _repository = repository ?? RenewalRepository();

  final RenewalRepository _repository;
  final devices = <DeviceModel>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
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
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final raw = data['list'] is List
          ? data['list'] as List
          : data['rows'] is List
          ? data['rows'] as List
          : const <dynamic>[];
      devices.assignAll(
        raw.whereType<Map>().map(
          (item) => DeviceModel.fromJson(jsonMapFrom(item)),
        ),
      );
    } catch (_) {
      errorMessage.value = '获取设备列表失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void startRenewal(DeviceModel device) => AppToast.show('提示', '请在微信小程序中完成充值');
}
