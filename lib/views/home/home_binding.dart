import 'package:get/get.dart';

import 'home_controller.dart';
import 'home_repository.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeRepository>(() => HomeRepository());
    // 常驻：首页仅在「应用打开」时由 onInit 加载一次；
    // 从其它页面返回首页时复用同一实例，不再重复调用接口（除非手动刷新）。
    if (!Get.isRegistered<HomeController>()) {
      Get.put(
        HomeController(repository: Get.find<HomeRepository>()),
        permanent: true,
      );
    }
  }
}
