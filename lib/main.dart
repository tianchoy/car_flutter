import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:car/services/device_position_cache.dart';
import 'package:car/services/push/push_bootstrap.dart';
import 'package:car/services/url.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  // 推送：注册前后台监听（回到前台时刷新 RegistrationID、清除角标）。
  // 真正的 JPush 初始化延后到登录成功后，由 PushBootstrap 触发。
  PushBootstrap.attachLifecycle();
  // 加载真实版本号（来自 pubspec.yaml 的 version），使 app 内展示与
  // 提交到应用商店的版本保持一致。
  await AppConfig.initAppInfo();
  // 预加载设备定位缓存到内存：使详情/跟踪/回放/围栏页在首帧即可拿到车辆
  // 上次位置，避免地图先用默认坐标（北京）构建、再跳到真实位置。
  await DevicePositionCache.prime();
  // 安卓端：系统状态栏（顶部安全区）背景与顶部导航栏保持一致，避免出现异色条。
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: CupertinoColors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }
  runApp(const App());
}
