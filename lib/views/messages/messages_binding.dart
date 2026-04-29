import 'package:get/get.dart';
import 'messages_controller.dart';

class MessagesBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessagesController>(() => MessagesController());
  }
}
