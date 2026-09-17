import 'package:get/get.dart';

import 'messages_controller.dart';
import 'messages_repository.dart';

class MessagesBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessagesRepository>(() => MessagesRepository());
    Get.lazyPut<MessagesController>(
      () => MessagesController(repository: Get.find<MessagesRepository>()),
    );
  }
}
