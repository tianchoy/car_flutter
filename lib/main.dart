import 'dart:io';

import 'package:car/services/device_position_cache.dart';
import 'package:car/services/push/push_bootstrap.dart';
import 'package:car/services/url.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  PushBootstrap.attachLifecycle();
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
