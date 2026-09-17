import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../shared/widgets/reference_ui.dart';
import 'route_observer.dart';
import 'router_instance.dart';
import '../views/home/home_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetCupertinoApp(
      title: '车联网',
      theme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.page,
        barBackgroundColor: CupertinoColors.systemBackground,
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: AppColors.text,
            fontFamily: 'PingFang SC',
            fontSize: 16,
          ),
          actionTextStyle: TextStyle(
            color: AppColors.primary,
            fontFamily: 'PingFang SC',
            fontSize: 16,
          ),
          navTitleTextStyle: TextStyle(
            color: AppColors.text,
            fontFamily: 'PingFang SC',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.text,
            fontFamily: 'PingFang SC',
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
          tabLabelTextStyle: TextStyle(
            color: AppColors.secondaryText,
            fontFamily: 'PingFang SC',
            fontSize: 10,
          ),
          pickerTextStyle: TextStyle(
            color: AppColors.text,
            fontFamily: 'PingFang SC',
            fontSize: 21,
          ),
        ),
      ),
      initialRoute: Routes.startup,
      getPages: AppRouter.routes,
      navigatorObservers: [routeObserver],
      // 退出登录进入登录页时销毁常驻的首页控制器，保证下次登录进入首页时
      // 重新触发 onInit 拉取最新数据（而非显示上一个账号的残留数据）。
      routingCallback: (routing) {
        if (routing?.current == Routes.login) {
          Get.delete<HomeController>(force: true);
        }
      },
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
    );
  }
}
