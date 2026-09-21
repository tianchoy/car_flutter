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

  /// 从首页平台接口读取的目标微信小程序 AppID；为空时暂不可跳转。
  final platformAppId = RxnString();
  final platformAppErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    platformAppErrorMessage.value = '';
    platformAppId.value = null;
    try {
      await Future.wait<void>([_loadDevices(), _loadPlatformAppId()]);
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> _loadDevices() async {
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
    }
  }

  Future<void> _loadPlatformAppId() async {
    try {
      final response = await _repository.fetchPlatformAppId();
      final result = ApiResponse<String?>.fromJson(
        response.data,
        dataParser: (data) {
          final appId = stringValue(data).trim();
          return appId.isEmpty ? null : appId;
        },
      );
      if (!result.isSuccess) {
        platformAppErrorMessage.value = result.message.isEmpty
            ? '获取续费平台信息失败'
            : result.message;
        return;
      }
      platformAppId.value = result.data;
    } catch (_) {
      platformAppErrorMessage.value = '获取续费平台信息失败，请稍后重试';
    }
  }

  void startRenewal(DeviceModel device) => AppToast.show('提示', '请在微信小程序中完成充值');
}
