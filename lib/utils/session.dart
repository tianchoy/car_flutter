import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger.dart';

class SessionKeys {
  SessionKeys._();

  static const String token = 'token';
  static const String userProfile = 'user.profile';
  static const String userType = 'user.type';
  static const String selectedDeviceInfo = 'selected_device_info';
  static const String selectedDeviceIndex = 'selected_device_index';
  /// 个人中心「我的车辆」数量缓存：首屏直接展示上次数值，避免 0 跳成真实数量。
  static const String profileVehicleCount = 'profile.vehicle_count';
  /// 各设备最近一次成功获取的定位（JSON：设备号 -> {latitude, longitude}）。
  static const String deviceLastPositions = 'device.last_positions';
  static const String pushRegistrationId = 'push.registration_id.jpush';
  static const String pushSession = 'push.session.jpush';
  static const String pendingPushMessageId = 'push.pending_message_id.jpush';
  static const String pushMessageStale = 'push.message_stale.jpush';

  static const Set<String> authenticated = <String>{
    token,
    userProfile,
    userType,
    selectedDeviceInfo,
    selectedDeviceIndex,
    profileVehicleCount,
    pushSession,
    pendingPushMessageId,
    pushMessageStale,
  };
}

/// Compatibility helpers used by the existing project.
Future<void> setSession(String key, String value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  } catch (error, stackTrace) {
    Log.e('Error setting session', error: error, stackTrace: stackTrace);
    rethrow;
  }
}

Future<String?> getSession(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  } catch (error, stackTrace) {
    Log.e('Error getting session', error: error, stackTrace: stackTrace);
    return null;
  }
}

Future<void> deleteSession(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  } catch (error, stackTrace) {
    Log.e('Error deleting session', error: error, stackTrace: stackTrace);
    rethrow;
  }
}

Future<bool> hasAuthenticatedSession() async {
  final token = await getSession(SessionKeys.token);
  return token != null && token.trim().isNotEmpty;
}

Future<void> clearAuthenticatedSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(SessionKeys.authenticated.map(prefs.remove));
  } catch (error, stackTrace) {
    Log.e(
      'Error clearing authenticated session',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
