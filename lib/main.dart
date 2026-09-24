import 'dart:async';
import 'dart:io';

import 'package:car/services/device_position_cache.dart';
import 'package:car/services/push/push_bootstrap.dart';
import 'package:car/services/push/push_service.dart';
import 'package:car/services/url.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  PushBootstrap.attachLifecycle();
  // 启动即清一次角标：推送初始化在登录后才进行，未登录 / token 过期时
  // 也不能让主屏图标残留角标（不等待，避免拖慢首帧）。
  unawaited(PushService.to.clearBadge());
  await AppConfig.initAppInfo();
  await DevicePositionCache.prime();
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
