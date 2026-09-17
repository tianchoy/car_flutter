import 'package:get/get.dart';

import 'device_share_controller.dart';
import 'device_share_repository.dart';

class DeviceShareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeviceShareRepository>(() => DeviceShareRepository());
    Get.lazyPut<DeviceShareController>(
      () =>
          DeviceShareController(repository: Get.find<DeviceShareRepository>()),
    );
  }
}
