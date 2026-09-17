import 'package:get/get.dart';

import 'pay_device_list_controller.dart';
import 'package:car/views/account/renewal/renewal_repository.dart';

class PayDeviceListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RenewalRepository>(() => RenewalRepository());
    Get.lazyPut<PayDeviceListController>(
      () => PayDeviceListController(repository: Get.find<RenewalRepository>()),
    );
  }
}
