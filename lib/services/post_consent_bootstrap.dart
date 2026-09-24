import 'dart:async';

import '../utils/logger.dart';
import 'device_position_cache.dart';
import 'push/push_bootstrap.dart';
import 'push/push_service.dart';

/// 「用户已同意《隐私政策》」之后才允许执行的初始化动作。
///
/// 合规要求：在用户点击同意之前，App 不得初始化任何会采集个人信息的第三方
/// SDK，也不得读取与用户相关的本地数据。极光推送 SDK 会在首次调用其接口
/// （[PushService.clearBadge]）时完成初始化，因此这些动作统一收拢到这里，
/// 由 [main]（本次启动前就已同意时）或隐私政策同意页（本次刚同意时）触发，
/// 每个进程只执行一次。
class PostConsentBootstrap {
  PostConsentBootstrap._();

  static bool _done = false;

  static bool get hasRun => _done;

  /// [awaitSdkInitialization] 为 true 时会等待 SDK 侧调用完成后再返回。
  ///
  /// 首次安装、用户在同意页点了「同意」后马上要进登录页输入：若此时把 SDK 调用
  /// 丢给事件循环，它会与用户首次聚焦输入框（首次弹出键盘）叠加，表现为输入卡顿。
  /// 因此首次同意路径传 true，把这段开销留在同意页的 loading 里；
  /// 冷启动（已同意，`main` 中调用）传 false，不拖慢首帧。
  static Future<void> run({bool awaitSdkInitialization = false}) async {
    if (_done) return;
    _done = true;
    Log.d('隐私政策已同意，开始执行同意后的初始化');
    // 前后台切换监听内部会清理角标（触达极光 SDK），因此必须在同意后注册。
    PushBootstrap.attachLifecycle();
    final badgeCleanup = PushService.to.clearBadge();
    if (awaitSdkInitialization) {
      await badgeCleanup;
    } else {
      // 清角标不阻塞首帧，交给事件循环即可。
      unawaited(badgeCleanup);
    }
    await DevicePositionCache.prime();
  }
}
