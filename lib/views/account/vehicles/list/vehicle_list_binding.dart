import 'package:get/get.dart';

import 'vehicle_list_controller.dart';
import 'vehicle_list_repository.dart';

class VehicleListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VehicleListRepository>(() => VehicleListRepository());
    Get.lazyPut<VehicleListController>(
      () =>
          VehicleListController(repository: Get.find<VehicleListRepository>()),
    );
  }
}
