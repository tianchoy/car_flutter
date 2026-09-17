import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../utils/session.dart';

class StartupRouteService {
  StartupRouteService._();

  static Future<String> resolve() async {
    return await hasAuthenticatedSession() ? Routes.home : Routes.login;
  }
}

class StartupController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _redirect();
  }

  Future<void> _redirect() async {
    final route = await StartupRouteService.resolve();
    if (!isClosed && Get.currentRoute == Routes.startup) {
      Get.offAllNamed(route);
    }
  }
}
