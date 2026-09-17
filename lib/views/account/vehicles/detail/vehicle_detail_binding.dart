import 'package:get/get.dart';

import 'vehicle_detail_controller.dart';
import 'vehicle_detail_repository.dart';

class VehicleDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehicleDetailRepository>(() => VehicleDetailRepository());
    Get.lazyPut<VehicleDetailController>(
      () => VehicleDetailController(
        repository: Get.find<VehicleDetailRepository>(),
      ),
    );
  }
}
