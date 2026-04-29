// shared/services/navigation_service.dart
import 'package:get/get.dart';
import '../../app/router_instance.dart';

class NavigationService {
  static const int homeIndex = 0;
  static const int messagesIndex = 1;
  static const int profileIndex = 2;

  static void navigateTo(int index) {
    if (Get.currentRoute == _getRouteName(index)) return;

    switch (index) {
      case homeIndex:
        Get.offAllNamed(Routes.home);
        break;
      case messagesIndex:
        Get.offAllNamed(Routes.messages);
        break;
      case profileIndex:
        Get.offAllNamed(Routes.profile);
        break;
    }
  }

  static String _getRouteName(int index) {
    switch (index) {
      case homeIndex:
        return Routes.home;
      case messagesIndex:
        return Routes.messages;
      case profileIndex:
        return Routes.profile;
      default:
        return Routes.home;
    }
  }

  static int getCurrentIndex() {
    switch (Get.currentRoute) {
      case Routes.home:
        return homeIndex;
      case Routes.messages:
        return messagesIndex;
      case Routes.profile:
        return profileIndex;
      default:
        return homeIndex;
    }
  }
}
