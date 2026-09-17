import 'package:get/get.dart';

import 'register_controller.dart';
import 'register_repository.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterRepository>(() => RegisterRepository());
    Get.lazyPut<RegisterController>(
      () => RegisterController(repository: Get.find<RegisterRepository>()),
    );
  }
}
