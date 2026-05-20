import 'package:get/get.dart';

import '../../model/profile/profile_model.dart';
import '../../utils/Logger.dart';
import 'profile_repository.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ProfileRepository _repository = ProfileRepository();
  final isLoggedIn = false.obs;
  final profile = Rx<UserModel?>(null);

  @override
  void onInit() async {
    super.onInit();
    if (await isLogin()) {
      await fetchProfile();
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  // 获取用户信息API
  Future<void> fetchProfile() async {
    try {
      final response = await _repository.fetchProfile();
      if (response.data != null && response.data['code'] == 0) {
        profile.value = UserModel.fromJson(response.data['data']);
      } else {
        Log.e('响应错误: ${response.data['msg']}');
      }
    } catch (e) {
      Log.e('获取用户信息失败: $e');
      Get.snackbar('错误', '获取用户信息失败');
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    Get.offAllNamed('/');
  }

  Future<bool> isLogin() async {
    try {
      final token = await _repository.getToken();
      isLoggedIn.value = token != null && token.isNotEmpty;
      return isLoggedIn.value;
    } catch (e) {
      isLoggedIn.value = false;
      return false;
    }
  }
}
