import 'dart:io';

/// 极光推送（JPush）客户端配置。
///
/// AppKey / channel 与 uni-app X 源工程（carConnectInternet）保持一致：
/// - `services/push.uts` 的 `JPUSH_APP_KEY`
/// - `nativeResources/android/manifestPlaceholders.json` 的 `JPUSH_APPKEY`
/// - 本地离线打包工程 `car/app/build.gradle` 的 `jpushAppKey`
///
/// AppKey 属于公开标识（与包名绑定），可以随包分发；JPush Master Secret
/// 只能留在极光控制台或后端密钥库，禁止写入客户端代码。
class PushConfig {
  PushConfig._();

  /// JPush 应用 AppKey（Android / iOS 共用同一个极光应用）。
  ///
  /// 该 AppKey 在极光控制台绑定包名 `com.zdiot.app`；若再次更换包名，必须先在
  /// 极光控制台登记新包名并取新 AppKey，再同步修改此处与
  /// `android/app/build.gradle.kts` 的 `manifestPlaceholders["JPUSH_APPKEY"]`。
  static const String appKey = '0ee065e1a4024ce1801fa6d3';

  /// 下发渠道，沿用原工程的 `developer-default`。
  static const String channel = 'developer-default';

  /// iOS APNs 环境：Release / TestFlight / App Store 必须为 true。
  /// 开发期可用沙箱调试时临时改为 false。
  static const bool iosProduction = true;

  /// Android 端 JPush SDK 从 AndroidManifest 的 `JPUSH_APPKEY` meta-data 读取
  /// AppKey（见 android/app/build.gradle.kts 的 manifestPlaceholders），
  /// 因此 Dart 侧传空串，避免两处配置不一致。
  static String get setupAppKey => Platform.isAndroid ? '' : appKey;

  /// RegistrationID 首次获取失败后的重试策略（对齐源工程：3 秒 × 5 次）。
  static const int registrationMaxRetry = 5;
  static const Duration registrationRetryDelay = Duration(seconds: 3);

  /// 登录成功后延后初始化推送，避免与登录跳转、首屏数据请求抢资源。
  static const Duration postLoginInitDelay = Duration(milliseconds: 1200);
}
