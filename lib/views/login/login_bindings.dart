import 'package:get/get.dart';

import 'login_controller.dart';
import 'login_repository.dart';

class LoginBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginRepository>(() => LoginRepository());
    Get.lazyPut<LoginController>(
      () => LoginController(loginRepository: Get.find<LoginRepository>()),
    );
  }
}
