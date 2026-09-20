import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Configuration shared by the mobile App targets.
///
/// Runtime values may be overridden through `.env`; source-compatible defaults
/// keep development builds aligned with the UniApp X App backend.
class AppConfig {
  AppConfig._();

  static const String defaultApiBaseUrl = 'https://gpsapp.zdiot.cn';
  static const String clientId = '428a8310cd442757ae699df5d894f051';
  static const String tenantId = '000000';
  /// Android 应用 ID：与 android/app/build.gradle.kts 的 applicationId 保持一致，
  /// 用于地图 SDK 的 userAgent（高德/腾讯地图要求传应用包名）。
  static const String androidPackageName = 'com.zdiot.app';

  /// 展示在「个人中心」等处的软件名称（品牌名，不随发版变化，保留在代码里）。
  static const String appName = '中导物联';

  /// 版本号与构建号，均由 [initAppInfo] 在启动时从 pubspec.yaml 的
  /// `version` 字段读取，确保与提交到应用商店的版本完全一致。
  /// 你只需修改 pubspec.yaml 的 version（如 `1.0.0+1` → `1.1.0+2`），
  /// 商店更新提示与 app 内展示即可同步，无需再维护此处硬编码。
  static String appVersion = '1.0.0';
  static String appBuildNumber = '1';
  static String get appVersionLabel => '$appName v$appVersion ($appBuildNumber)';

  /// 在 main() 中 runApp 之前调用，加载真实版本信息。
  static Future<void> initAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      appBuildNumber = info.buildNumber;
    } catch (_) {
      // 读取失败时保留默认值，避免展示空白
    }
  }

  static const String amapTileUrl =
      'https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7';

  static String get apiBaseUrl {
    final configuredValue = dotenv.env['API_URL']?.trim();
    return configuredValue == null || configuredValue.isEmpty
        ? defaultApiBaseUrl
        : configuredValue;
  }
}

class ApiEndpoints {
  ApiEndpoints._();

  static const String legacyLogin = '/sys/login';
  static const String authLogin = '/auth/login';
  static const String logout = '/auth/logout';
  static const String smsCode = '/resource/sms/code';
  static const String register = '/auth/register';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';
  static const String changePassword = '/user/profile/updatePassword';

  /// 获取当前登录用户个人信息（仅登录态，token 只放请求头）。
  /// 已统一替换旧的 /sys/user/info（个人中心与个人信息页均使用此接口）。
  static const String appUserProfile = '/system/appUser/profile';
  static const String userDeviceList = '/userDevice/list';
  static const String deviceLastPosition = '/gps/lastPosition';
  static const String trackPosition = '/gps/trackPos';
  static const String messages = '/usermessage/listForUser';
  static const String messageDetail = '/usermessage/detail/';
  static const String messageUnreadCount = '/app/message/unreadCount';

  static const String deviceInfo = '/device/info/';
  static const String updateDevice = '/device/update';
  static const String addDevice = '/userDevice/add';
  static const String deleteDevice = '/userDevice/del';
  static const String carTypes = '/carType/listAll';

  static const String geofence = '/geofence';
  static const String geofenceDelete = '/geofence/';
  static const String unboundGeofenceDevices = '/device/unbindGeofenceList';
  static const String boundGeofenceDevices = '/device/bindGeofenceList';
  static const String bindGeofenceDevices = '/geofence/bind';
  static const String unbindGeofenceDevices = '/geofence/unbind';

  static const String commandSend = '/command/sendCmd';
  static const String availableAppCommands = '/app/command/available-cmds';
  static const String sendAppCommand = '/app/command/send';
  static const String appCommandHistory = '/app/command/list';
  static const String appCommandDetail = '/app/command/';
  static const String retryAppCommand = '/app/command/retry/';

  static const String pushBind = '/app/push/bind';
  static const String pushUnbind = '/app/push/unbind';
  static const String geocoderAddress = '/geocoder/address';

  static const String deviceShare = '/share/device';
  static const String deviceShareSent = '/share/device/sent';
  static const String deviceShareReceived = '/share/device/received';
  static const String deviceShareEnabled = '/share/device/enabled';
  static const String deviceShareExit = '/share/device/exit';
}

/// Backwards-compatible accessors used by existing widgets and repositories.
String get baseUrl => AppConfig.apiBaseUrl;
String get mapUrl => AppConfig.amapTileUrl;
String get loginUrl => ApiEndpoints.authLogin;
String get logoutUrl => ApiEndpoints.logout;
String get userDeviceList => ApiEndpoints.userDeviceList;
String get messagesListUrl => ApiEndpoints.messages;
String get trackPos => ApiEndpoints.trackPosition;
