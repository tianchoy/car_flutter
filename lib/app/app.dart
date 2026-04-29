import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '中导物联',
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'PingFang SC',
        brightness: Brightness.light,
      ),
      initialRoute: AppRouter.routes[0].name,
      getPages: AppRouter.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
    );
  }
}
