import 'package:get/get.dart';

import 'scan_code_controller.dart';
import 'scan_code_repository.dart';

class ScanCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScanCodeRepository>(() => ScanCodeRepository());
    Get.lazyPut<ScanCodeController>(
      () => ScanCodeController(repository: Get.find<ScanCodeRepository>()),
    );
  }
}
