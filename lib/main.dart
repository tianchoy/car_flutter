import 'dart:io';

import 'package:car/services/post_consent_bootstrap.dart';
import 'package:car/services/privacy_consent_service.dart';
import 'package:car/services/url.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await AppConfig.initAppInfo();

  // 合规：用户同意《隐私政策》之前，不得初始化会采集个人信息的第三方 SDK
  // （极光推送及华为/荣耀/小米/OPPO 厂商通道），也不得读取与用户相关的本地
  // 缓存。这些动作统一收拢在 PostConsentBootstrap 中：本次启动前已同意过的
  // 用户在此执行；首次启动的用户由隐私政策同意页在点击「同意」后执行。
  if (await PrivacyConsentService.hasConsented()) {
    await PostConsentBootstrap.run();
  }

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
