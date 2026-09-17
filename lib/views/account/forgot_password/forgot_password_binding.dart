import 'package:get/get.dart';

import 'forgot_password_controller.dart';
import 'forgot_password_repository.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPasswordRepository>(() => ForgotPasswordRepository());
    Get.lazyPut<ForgotPasswordController>(
      () => ForgotPasswordController(
        repository: Get.find<ForgotPasswordRepository>(),
      ),
    );
  }
}
