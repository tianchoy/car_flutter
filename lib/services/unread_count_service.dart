import 'dart:async';

import 'package:get/get.dart';

import '../models/api_response.dart';
import '../utils/logger.dart';
import 'api_service.dart';

/// 未读消息数的全局唯一数据源。
///
/// 底部 tabbar「消息」角标与消息页的未读横幅共用同一个 [count]：
/// - 只由「未读数接口」的返回值（[refresh]）或已读操作（[set] / [clear]）写入，
///   避免两处各自维护导致「角标和页面不一致」；
/// - 角标文案统一走 [badgeText]：超过 99 显示 `99+`，为 0 时返回 null 表示不展示。
class UnreadCountService {
  UnreadCountService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  static final UnreadCountService instance = UnreadCountService();
  static UnreadCountService get to => instance;

  final ApiService _apiService;

  /// 当前未读数（响应式）：0 表示不展示角标。
  final count = 0.obs;

  bool _requesting = false;

  /// 角标文案：1~99 原样、超过 99 显示 `99+`、0 返回 null（不展示角标）。
  String? get badgeText {
    final value = count.value;
    if (value <= 0) return null;
    return value > 99 ? '99+' : '$value';
  }

  /// 拉取未读数并写入 [count]。失败时保留旧值，不无故清掉角标。
  Future<void> refresh() async {
    if (_requesting) return;
    _requesting = true;
    try {
      final response = await _apiService.getUnreadMessageCount();
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) set(intValue(result.data));
    } catch (error) {
      Log.w('获取未读消息数失败: $error');
    } finally {
      _requesting = false;
    }
  }

  /// 推送到达/点击后刷新：消息落库通常滞后于推送（用户此时点进消息页也看不到
  /// 这条新消息），因此立即取一次、2 秒后再校准一次。
  Future<void> refreshAfterPush() async {
    await refresh();
    await Future<void>.delayed(const Duration(seconds: 2));
    await refresh();
  }

  /// 直接写入未读数（消息页加载列表 / 逐个已读后同步用）。
  void set(int value) => count.value = value < 0 ? 0 : value;

  /// 清空角标：一键已读成功、或退出登录。
  void clear() => count.value = 0;
}
