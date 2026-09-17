import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/models/api_response.dart';
import 'package:car/models/profile/profile_model.dart';
import 'package:car/services/session_expiry_coordinator.dart';
import 'user_info_repository.dart';

class UserInfoController extends GetxController {
  UserInfoController({UserInfoRepository? repository})
    : _repository = repository ?? UserInfoRepository();

  final UserInfoRepository _repository;

  /// 当前登录用户的个人信息。
  final profile = Rxn<UserProfileModel>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// 拉取当前登录用户的个人信息（GET /system/appUser/profile）。
  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await _repository.fetchUserProfile();
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isTokenExpired) {
        await SessionExpiryCoordinator.handleExpiredSession();
        return;
      }
      if (result.isSuccess) {
        final data = result.data;
        profile.value = data == null ? null : UserProfileModel.fromJson(data);
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

  void openChangePassword() => Get.toNamed(Routes.changePassword);
}
