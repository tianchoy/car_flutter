import 'package:get/get.dart';

import 'geofence_controller.dart';
import 'geofence_repository.dart';

class GeofenceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GeofenceRepository>(() => GeofenceRepository());
    Get.lazyPut<GeofenceController>(
      () => GeofenceController(repository: Get.find<GeofenceRepository>()),
    );
  }
}
