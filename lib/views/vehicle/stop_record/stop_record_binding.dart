import 'package:get/get.dart';

import 'stop_record_controller.dart';
import 'stop_record_repository.dart';

class StopRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StopRecordRepository>(() => StopRecordRepository());
    Get.lazyPut<StopRecordController>(
      () => StopRecordController(repository: Get.find<StopRecordRepository>()),
    );
  }
}
