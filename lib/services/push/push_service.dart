import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';

import '../../app/routes/router_instance.dart';
import '../../services/navigation_service.dart';
import '../../utils/logger.dart';
import '../../utils/session.dart';
import 'push_config.dart';

/// 推送事件类型：对齐源工程 push.uts 的 `PushEventKind`。
enum PushEventKind { received, clicked, custom }

typedef PushRegistrationIdListener = void Function(String registrationId);
typedef PushEventListener = void Function(PushEventKind kind, String messageId);

/// JPush 运行时封装：初始化、RegistrationID 缓存与重试、推送事件归一化。
///
/// 行为与 uni-app X 源工程 `services/push.uts` 保持一致：
/// - 注册事件回调后再初始化 SDK；
/// - RegistrationID 为空时按 3 秒间隔重试，最多 5 次；
/// - RegistrationID、待处理 `messageId`、消息刷新标记按 JPush 维度缓存；
/// - 点击通知时切换到消息页，收到推送时标记消息中心需要刷新；
/// - iOS 角标固定为 0（本应用没有服务端同步的全局未读数）。
class PushService {
  PushService._();

  static final PushService instance = PushService._();
  static PushService get to => instance;

  final JPushFlutterInterface _jpush = JPush.newJPush();

  final List<PushRegistrationIdListener> _registrationListeners =
      <PushRegistrationIdListener>[];
  final List<PushRegistrationIdListener> _sessionListeners =
      <PushRegistrationIdListener>[];
  final List<PushEventListener> _eventListeners = <PushEventListener>[];

  bool _initialized = false;
  bool _registrationRequesting = false;
  int _registrationRetryCount = 0;
  Timer? _registrationRetryTimer;

  bool get isInitialized => _initialized;

  /// 初始化 JPush（幂等）。必须在已登录的前提下调用，见 [PushBootstrap]。
  Future<void> init() async {
    if (_initialized) {
      unawaited(refreshRegistrationId());
      return;
    }
    _initialized = true;
    Log.d('已选择推送 provider: jpush');
    try {
      _jpush.addEventHandler(
        onReceiveNotification: (event) {
          _handleEvent(PushEventKind.received, event);
          return Future<dynamic>.value();
        },
        onReceiveMessage: (event) {
          _handleEvent(PushEventKind.custom, event);
          return Future<dynamic>.value();
        },
        onOpenNotification: (event) {
          _handleEvent(PushEventKind.clicked, event);
          return Future<dynamic>.value();
        },
        onConnected: (event) {
          final connected = event['result'] == true ||
              event['result']?.toString() == 'true';
          if (connected) unawaited(refreshRegistrationId());
          return Future<dynamic>.value();
        },
      );
      if (Platform.isIOS) {
        Log.d(
          '初始化 JPush iOS，APNs 环境: '
          '${PushConfig.iosProduction ? 'production' : 'development'}',
        );
      }
      _jpush.setup(
        appKey: PushConfig.setupAppKey,
        channel: PushConfig.channel,
        production: PushConfig.iosProduction,
        debug: kDebugMode,
      );
      if (Platform.isAndroid) {
        // Android 13+ 需要 POST_NOTIFICATIONS 才能弹出通知。
        _jpush.requestRequiredPermission();
      }
    } catch (error, stackTrace) {
      Log.e('初始化 JPush 失败', error: error, stackTrace: stackTrace);
    }
    unawaited(refreshRegistrationId());
  }

  /// 刷新 RegistrationID（启动、回到前台、登录成功后调用）。
  Future<void> refreshRegistrationId() async {
    if (!_initialized || _registrationRequesting) return;
    _registrationRequesting = true;
    String registrationId = '';
    try {
      registrationId = (await _jpush.getRegistrationID()).trim();
    } catch (error, stackTrace) {
      Log.e('获取 JPush RegistrationID 失败', error: error, stackTrace: stackTrace);
    }
    _registrationRequesting = false;
    if (registrationId.isEmpty) {
      _scheduleRegistrationRetry('JPush RegistrationID 为空');
      return;
    }
    await _saveRegistrationId(registrationId);
  }

  /// 标记当前会话已登录：立即用缓存的 RegistrationID 补发绑定。
  Future<void> markAuthenticated() async {
    await setSession(SessionKeys.pushSession, 'authenticated');
    final cached = await getCachedRegistrationId();
    unawaited(refreshRegistrationId());
    for (final listener in List.of(_sessionListeners)) {
      _notify(listener, cached);
    }
  }

  /// 退出登录时清掉与账号绑定的推送状态（RegistrationID 是设备标识，保留）。
  Future<void> clearSessionState() async {
    await deleteSession(SessionKeys.pushSession);
    await deleteSession(SessionKeys.pendingPushMessageId);
    await deleteSession(SessionKeys.pushMessageStale);
  }

  /// 清除角标：iOS 清系统角标与 JPush 记录值，Android 仅在支持的机型生效。
  Future<void> clearBadge() async {
    try {
      await _jpush.setBadge(0);
    } catch (error) {
      Log.w('清除应用角标失败: $error');
    }
  }

  Future<String> getCachedRegistrationId() async =>
      (await getSession(SessionKeys.pushRegistrationId))?.trim() ?? '';

  /// 取出并清除待处理的业务消息 ID。
  Future<String> consumePendingMessageId() async {
    final value = (await getSession(SessionKeys.pendingPushMessageId))?.trim() ?? '';
    await deleteSession(SessionKeys.pendingPushMessageId);
    return value;
  }

  /// 取出并清除「消息中心需要刷新」标记。
  Future<bool> consumeStaleFlag() async {
    final value = (await getSession(SessionKeys.pushMessageStale))?.trim() ?? '';
    await deleteSession(SessionKeys.pushMessageStale);
    return value == 'true';
  }

  void addRegistrationIdListener(PushRegistrationIdListener listener) =>
      _registrationListeners.add(listener);

  void addSessionAuthenticatedListener(PushRegistrationIdListener listener) =>
      _sessionListeners.add(listener);

  void addEventListener(PushEventListener listener) =>
      _eventListeners.add(listener);

  void removeEventListener(PushEventListener listener) =>
      _eventListeners.remove(listener);

  Future<void> _saveRegistrationId(String registrationId) async {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = null;
    _registrationRetryCount = 0;
    await setSession(SessionKeys.pushRegistrationId, registrationId);
    // RegistrationID 属于设备推送标识，生产日志不输出具体值。
    Log.d('JPush RegistrationID 已就绪');
    for (final listener in List.of(_registrationListeners)) {
      _notify(listener, registrationId);
    }
  }

  void _scheduleRegistrationRetry(String reason) {
    if (_registrationRetryCount >= PushConfig.registrationMaxRetry) {
      Log.w('设备注册 ID 获取超时，已停止重试。原因: $reason');
      return;
    }
    if (_registrationRetryTimer != null) return;
    _registrationRetryCount += 1;
    _registrationRetryTimer = Timer(PushConfig.registrationRetryDelay, () {
      _registrationRetryTimer = null;
      unawaited(refreshRegistrationId());
    });
  }

  void _handleEvent(PushEventKind kind, Map<String, dynamic> payload) {
    unawaited(clearBadge());
    final messageId = _extractMessageId(payload);
    unawaited(_persistPushEvent(kind, messageId));
    for (final listener in List.of(_eventListeners)) {
      _notifyEvent(listener, kind, messageId);
    }
    if (kind == PushEventKind.clicked) unawaited(_navigateToMessages());
  }

  Future<void> _persistPushEvent(PushEventKind kind, String messageId) async {
    if (messageId.isNotEmpty) {
      await setSession(SessionKeys.pendingPushMessageId, messageId);
    }
    await setSession(SessionKeys.pushMessageStale, 'true');
  }

  /// 点击通知后进入消息页（等价于源工程的 `uni.switchTab`）。
  Future<void> _navigateToMessages() async {
    final token = await getSession(SessionKeys.token);
    if (token == null || token.trim().isEmpty) return;
    if (Get.currentRoute == Routes.messages) return;
    NavigationService.navigateTo(NavigationService.messagesIndex);
  }

  void _notify(PushRegistrationIdListener listener, String registrationId) {
    try {
      listener(registrationId);
    } catch (error, stackTrace) {
      Log.e('推送监听执行失败', error: error, stackTrace: stackTrace);
    }
  }

  void _notifyEvent(
    PushEventListener listener,
    PushEventKind kind,
    String messageId,
  ) {
    try {
      listener(kind, messageId);
    } catch (error, stackTrace) {
      Log.e('推送事件监听执行失败', error: error, stackTrace: stackTrace);
    }
  }

  /// 从 payload 提取业务消息 ID：依次尝试 `messageId`、`message_id`、`id`，
  /// 并向下查找 `data` / `extra` / `extras` / `notificationExtras` 等嵌套结构。
  ///
  /// JPush 的 `msgId` 是通道侧消息 ID，不作为业务消息 ID 的兜底。
  String _extractMessageId(Map<String, dynamic> payload) {
    for (final key in const ['messageId', 'message_id', 'id']) {
      final value = _findValue(payload, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _findValue(Object? node, String key) {
    if (node is Map) {
      final direct = node[key];
      if (direct != null) {
        final value = _stringify(direct);
        if (value.isNotEmpty) return value;
      }
      for (final nestedKey in const [
        'data',
        'extra',
        'extras',
        'notificationExtras',
      ]) {
        final value = _findValue(node[nestedKey], key);
        if (value.isNotEmpty) return value;
      }
      // 兜底：遍历一层未知嵌套结构（Android extras 会把业务字段再包一层）。
      for (final entry in node.entries) {
        final value = entry.value;
        if (value is Map || value is String) {
          final found = _findValue(value, key);
          if (found.isNotEmpty) return found;
        }
      }
      return '';
    }
    if (node is String && node.trim().startsWith('{')) {
      try {
        return _findValue(jsonDecode(node), key);
      } on FormatException {
        return '';
      }
    }
    return '';
  }

  String _stringify(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}
