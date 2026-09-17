import 'package:get/get.dart';

import 'mileage_controller.dart';
import 'mileage_repository.dart';

class MileageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MileageRepository>(() => MileageRepository());
    Get.lazyPut<MileageController>(
      () => MileageController(repository: Get.find<MileageRepository>()),
    );
  }
}
