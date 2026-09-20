import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../../models/api_response.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';
import '../../utils/session.dart';
import '../../services/url.dart';
import 'push_service.dart';

/// 把 JPush RegistrationID 绑定到当前登录账号（POST /app/push/bind）。
///
/// 行为与源工程 `services/push-binding.uts` 一致：
/// - 仅在 RegistrationID 就绪且存在有效登录 token 时提交；
/// - 同一 token + RegistrationID 组合在当前运行期内只成功绑定一次；
/// - 绑定失败不阻塞登录与跳转，后续 RegistrationID 刷新时可再次提交；
/// - 日志不记录 token 与 RegistrationID。
class PushBindingService {
  PushBindingService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  static final PushBindingService instance = PushBindingService();
  static PushBindingService get to => instance;

  final ApiService _apiService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  bool _initialized = false;
  bool _binding = false;
  String _bindingSessionKey = '';
  String _pendingRegistrationId = '';
  String _boundSessionKey = '';

  /// 注册绑定触发时机（幂等）：RegistrationID 就绪 / 登录会话就绪。
  void init() {
    if (_initialized) return;
    _initialized = true;
    PushService.to.addRegistrationIdListener(_bind);
    PushService.to.addSessionAuthenticatedListener((registrationId) {
      if (registrationId.isEmpty) {
        Log.d('用户已登录，但尚无缓存 RegistrationID');
        return;
      }
      Log.d('用户已登录，使用缓存 RegistrationID 绑定推送设备');
      _bind(registrationId);
    });
  }

  /// 退出登录时解绑当前设备；失败不影响退出流程。
  Future<void> unbindOnLogout() async {
    final registrationId = await PushService.to.getCachedRegistrationId();
    if (registrationId.isEmpty) {
      Log.d('退出登录时无缓存 RegistrationID，跳过推送设备解绑');
      return;
    }
    _boundSessionKey = '';
    try {
      final response = await _apiService.unbindPushDevice(registrationId);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        Log.d('推送设备解绑成功');
        return;
      }
      Log.w('推送设备解绑失败，但仍继续退出登录。code=${result.code}');
    } catch (error) {
      Log.w('推送设备解绑请求失败，但仍继续退出登录: $error');
    }
  }

  void _bind(String registrationId) {
    if (registrationId.isEmpty) return;
    getSession(SessionKeys.token).then((token) {
      final normalizedToken = token?.trim() ?? '';
      if (normalizedToken.isEmpty) {
        Log.d('RegistrationID 已就绪，等待用户登录');
        return;
      }
      final platform = _platform();
      if (platform.isEmpty) return;
      final sessionKey = '$normalizedToken:$registrationId';
      if (_binding) {
        if (_bindingSessionKey != sessionKey) {
          _pendingRegistrationId = registrationId;
        }
        return;
      }
      if (_boundSessionKey == sessionKey) return;
      _binding = true;
      _bindingSessionKey = sessionKey;
      _requestBind(registrationId, platform).whenComplete(() {
        _binding = false;
        _bindingSessionKey = '';
        final next = _pendingRegistrationId;
        _pendingRegistrationId = '';
        if (next.isNotEmpty) _bind(next);
      });
    });
  }

  Future<void> _requestBind(String registrationId, String platform) async {
    Log.d('开始绑定推送设备，platform=$platform');
    try {
      final deviceName = await _deviceName();
      // 与登录/短信等接口保持一致，body 带上 tenantId（其它接口都传，bind 之前漏了，
      // 后端若按 body 取租户可能 NPE 导致 500）。
      final body = <String, dynamic>{
        'registrationId': registrationId,
        'platform': platform,
        'deviceName': deviceName,
        'appVersion': AppConfig.appVersion,
        'tenantId': AppConfig.tenantId,
      };
      // 调试用：RegistrationID 属隐私不打印，其余字段全打，便于和 uniapp 联调时的请求体核对。
      Log.d(
        '绑定请求体: platform=$platform, deviceName=$deviceName, '
        'appVersion=${AppConfig.appVersion}, tenantId=${AppConfig.tenantId}',
      );
      final response = await _apiService.bindPushDevice(body);
      Log.d('绑定响应原文: ${response.data}');
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        _boundSessionKey = _bindingSessionKey;
        Log.d('推送设备绑定成功，platform=$platform');
        return;
      }
      Log.w('推送设备绑定失败，稍后将重试。code=${result.code}, msg=${result.message}');
    } catch (error) {
      Log.w('推送设备绑定请求失败，稍后将重试: $error');
    }
  }

  String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return '';
  }

  Future<String> _deviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.modelName.isNotEmpty ? info.modelName : info.model;
      }
    } catch (error) {
      Log.w('获取设备型号失败: $error');
    }
    return '';
  }
}
