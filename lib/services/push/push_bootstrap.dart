import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../utils/logger.dart';
import '../../utils/session.dart';
import 'push_binding_service.dart';
import 'push_config.dart';
import 'push_service.dart';

/// 推送初始化编排：登录后延后初始化，回到前台时刷新 RegistrationID 与角标。
///
/// 对齐源工程 `services/app-startup.uts`：推送注册不影响登录流程，
/// 因此在登录成功并完成首屏跳转后再初始化；已登录用户冷启动时由首页兜底触发。
class PushBootstrap {
  PushBootstrap._();

  static bool _servicesInitialized = false;
  static bool _initializationScheduled = false;
  static _PushLifecycleObserver? _lifecycleObserver;

  /// 在 main() 中注册一次：监听前后台切换。
  static void attachLifecycle() {
    if (_lifecycleObserver != null) return;
    _lifecycleObserver = _PushLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
  }

  /// 登录成功、或已登录用户冷启动时调用（内部保证只初始化一次）。
  static Future<void> schedulePostLoginInitialization() async {
    if (!await _hasLoginToken()) return;
    if (_servicesInitialized) {
      await _refreshInitializedServices();
      return;
    }
    if (_initializationScheduled) return;
    _initializationScheduled = true;
    Log.d('已安排登录后的推送初始化');
    Timer(PushConfig.postLoginInitDelay, () {
      unawaited(_initializeServices());
    });
  }

  /// 回到前台：刷新 RegistrationID 并清除角标。
  static Future<void> refreshOnResume() async {
    if (!_servicesInitialized) return;
    await PushService.to.refreshRegistrationId();
    await PushService.to.clearBadge();
  }

  static Future<void> _initializeServices() async {
    _initializationScheduled = false;
    if (!await _hasLoginToken()) {
      Log.d('当前未登录，跳过推送初始化');
      return;
    }
    if (_servicesInitialized) {
      await _refreshInitializedServices();
      return;
    }
    _servicesInitialized = true;
    Log.d('开始登录后的推送初始化');
    PushBindingService.to.init();
    await PushService.to.init();
    await PushService.to.clearBadge();
    await PushService.to.markAuthenticated();
    Log.d('登录后的推送初始化已触发');
  }

  static Future<void> _refreshInitializedServices() async {
    await PushService.to.refreshRegistrationId();
    await PushService.to.clearBadge();
    await PushService.to.markAuthenticated();
  }

  static Future<bool> _hasLoginToken() async {
    final token = await getSession(SessionKeys.token);
    return token != null && token.trim().isNotEmpty;
  }
}

class _PushLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(PushBootstrap.refreshOnResume());
  }
}
