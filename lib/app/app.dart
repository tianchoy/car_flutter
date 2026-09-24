import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../widgets/reference_ui.dart';
import 'routes/route_observer.dart';
import 'routes/router_instance.dart';
import '../views/home/home_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetCupertinoApp(
      title: '车联网',
      // 不再显式指定 fontFamily: 'PingFang SC'：iOS 中文默认即 PingFang SC，
      // 显式指定系统字体名会让引擎按名解析字体族（每次新建字号/字重组合都要走一次
      // 字体查找），首次安装后的输入场景（首次弹出键盘并由输入框测量字形）尤其容易
      // 出现一次性卡顿。去掉后 iOS 视觉不变，Android 行为也与原本的回退一致。
      theme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.page,
        barBackgroundColor: CupertinoColors.systemBackground,
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: AppColors.text, fontSize: 16),
          actionTextStyle: TextStyle(color: AppColors.primary, fontSize: 16),
          navTitleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          navLargeTitleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
          tabLabelTextStyle: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 10,
          ),
          pickerTextStyle: TextStyle(color: AppColors.text, fontSize: 21),
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
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    );
  }
}
