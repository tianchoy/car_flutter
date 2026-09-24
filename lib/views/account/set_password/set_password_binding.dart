import 'package:get/get.dart';

import 'set_password_controller.dart';
import 'set_password_repository.dart';

class SetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SetPasswordRepository>(() => SetPasswordRepository());
    Get.lazyPut<SetPasswordController>(
      () =>
          SetPasswordController(repository: Get.find<SetPasswordRepository>()),
    );
  }
}
