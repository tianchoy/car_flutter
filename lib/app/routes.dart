import 'package:get/get.dart';
import '../views/home/home_binding.dart';
import '../views/home/home_view.dart';
import '../views/login/login_bindings.dart';
import '../views/login/login_view.dart';
import '../views/messages/messages_binding.dart';
import '../views/messages/messages_view.dart';
import '../views/profile/profile_binding.dart';
import '../views/profile/profile_view.dart';
import 'router_instance.dart';

class AppRouter {
  static final routes = [
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.messages,
      page: () => const MessagesView(),
      binding: MessagesBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => LoginView(),
      binding: LoginBindings(),
      transition: Transition.cupertino,
    ),
  ];
}
