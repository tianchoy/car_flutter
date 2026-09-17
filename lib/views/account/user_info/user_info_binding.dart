import 'package:get/get.dart';

import 'user_info_controller.dart';
import 'user_info_repository.dart';

class UserInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserInfoRepository>(() => UserInfoRepository());
    Get.lazyPut<UserInfoController>(
      () => UserInfoController(repository: Get.find<UserInfoRepository>()),
    );
  }
}
