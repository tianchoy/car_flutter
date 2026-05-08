import 'package:get/get.dart';

import 'profile_repository.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ProfileRepository _repository = ProfileRepository();
  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    isLogin();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> logout() async {
    await _repository.logout();
    Get.offAllNamed('/');
  }

  Future<void> isLogin() async {
    isLoggedIn.value = await _repository.checkToken();
  }
}
