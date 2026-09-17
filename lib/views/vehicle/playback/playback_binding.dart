import 'package:get/get.dart';

import 'playback_controller.dart';
import 'playback_repository.dart';

class PlaybackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaybackRepository>(() => PlaybackRepository());
    Get.lazyPut<PlaybackController>(
      () => PlaybackController(repository: Get.find<PlaybackRepository>()),
    );
  }
}
