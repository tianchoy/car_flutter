import 'package:get/get.dart';

import 'change_password_controller.dart';
import 'change_password_repository.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePasswordRepository>(() => ChangePasswordRepository());
    Get.lazyPut<ChangePasswordController>(
      () => ChangePasswordController(
        repository: Get.find<ChangePasswordRepository>(),
      ),
    );
  }
}
