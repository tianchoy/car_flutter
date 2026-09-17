import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/models/api_response.dart';
import 'package:car/services/session_expiry_coordinator.dart';
import 'user_info_repository.dart';

class UserInfoController extends GetxController {
  UserInfoController({UserInfoRepository? repository})
    : _repository = repository ?? UserInfoRepository();

  final UserInfoRepository _repository;
  final info = <String, dynamic>{}.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await _repository.fetchUserInfo();
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isTokenExpired) {
        await SessionExpiryCoordinator.handleExpiredSession();
        return;
      }
      if (result.isSuccess) {
        info.assignAll(result.data ?? const <String, dynamic>{});
      } else {
        AppToast.show(
          '提示',
          result.message.isEmpty ? '获取用户信息失败' : result.message,
        );
      }
    } catch (_) {
      AppToast.show('提示', '获取用户信息失败，请稍后重试');
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  String value(List<String> keys, {String fallback = '--'}) {
    for (final key in keys) {
      final value = info[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  void openChangePassword() => Get.toNamed(Routes.changePassword);
}
