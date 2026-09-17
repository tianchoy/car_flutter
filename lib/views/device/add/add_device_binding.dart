import 'package:get/get.dart';

import 'add_device_controller.dart';
import 'add_device_repository.dart';

class AddDeviceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddDeviceRepository>(() => AddDeviceRepository());
    Get.lazyPut<AddDeviceController>(
      () => AddDeviceController(repository: Get.find<AddDeviceRepository>()),
    );
  }
}
