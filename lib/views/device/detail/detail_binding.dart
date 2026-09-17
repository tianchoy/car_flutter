import 'package:get/get.dart';

import 'detail_controller.dart';
import 'detail_repository.dart';

class DetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DetailRepository>(() => DetailRepository());
    Get.lazyPut<DetailController>(
      () => DetailController(repository: Get.find<DetailRepository>()),
    );
  }
}
