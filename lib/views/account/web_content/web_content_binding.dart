import 'package:get/get.dart';

import 'web_content_controller.dart';
import 'web_content_repository.dart';

class WebContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WebContentRepository>(() => WebContentRepository());
    Get.lazyPut<WebContentController>(
      () => WebContentController(repository: Get.find<WebContentRepository>()),
    );
  }
}
