import 'package:get/get.dart';

import 'commands_controller.dart';
import 'commands_repository.dart';

class CommandsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommandsRepository>(() => CommandsRepository());
    Get.lazyPut<CommandsController>(
      () => CommandsController(repository: Get.find<CommandsRepository>()),
    );
  }
}
