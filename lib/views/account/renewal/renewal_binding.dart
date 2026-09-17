import 'package:get/get.dart';

import 'renewal_controller.dart';
import 'renewal_repository.dart';

class RenewalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RenewalRepository>(() => RenewalRepository());
    Get.lazyPut<RenewalController>(
      () => RenewalController(repository: Get.find<RenewalRepository>()),
    );
  }
}
