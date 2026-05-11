import 'package:get/get.dart';

import '../../model/home/device_model.dart';
import 'detail_repository.dart';

class DetailController extends GetxController {
  final DetailRepository _detailRepository = DetailRepository();
  final DeviceModel? device = Get.arguments as DeviceModel?;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
