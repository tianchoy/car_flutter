import 'package:get/get.dart';

import 'device_list_controller.dart';
import 'device_list_repository.dart';

class DeviceListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeviceListRepository>(() => DeviceListRepository());
    Get.lazyPut<DeviceListController>(
      () => DeviceListController(repository: Get.find<DeviceListRepository>()),
    );
  }
}
