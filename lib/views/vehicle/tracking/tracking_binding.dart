import 'package:get/get.dart';

import 'tracking_controller.dart';
import 'tracking_repository.dart';

class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrackingRepository>(() => TrackingRepository());
    Get.lazyPut<TrackingController>(
      () => TrackingController(repository: Get.find<TrackingRepository>()),
    );
  }
}
