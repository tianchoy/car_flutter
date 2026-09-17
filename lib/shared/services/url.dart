import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration shared by the mobile App targets.
///
/// Runtime values may be overridden through `.env`; source-compatible defaults
/// keep development builds aligned with the UniApp X App backend.
class AppConfig {
  AppConfig._();

  static const String defaultApiBaseUrl = 'https://gpsapp.zdiot.cn';
  static const String clientId = '428a8310cd442757ae699df5d894f051';
  static const String tenantId = '000000';
  static const String androidPackageName = 'com.example.car';

  static const String amapTileUrl =
      'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}';

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

  static const String userInfo = '/sys/user/info';
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
String get userInfoUrl => ApiEndpoints.userInfo;
String get userDeviceList => ApiEndpoints.userDeviceList;
String get messagesListUrl => ApiEndpoints.messages;
String get trackPos => ApiEndpoints.trackPosition;
