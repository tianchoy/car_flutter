import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// 隐私政策同意状态。
///
/// 合规要求：App 首次启动时必须以显著方式提示用户阅读《隐私政策》，且在用户
/// 点击「同意」之前，不得收集任何个人信息，也不得初始化会采集个人信息的第三方
/// SDK。因此该状态必须在 [main] 中**最先**读取，未同意时跳过全部 SDK 初始化。
class PrivacyConsentService {
  PrivacyConsentService._();

  /// 版本化 key：当《隐私政策》发生实质性变更时递增版本号，
  /// 即可让老用户重新看到同意弹窗。
  static const String _agreedKey = 'legal.privacy_policy_agreed.v1';

  static bool? _cached;

  /// 是否已同意《隐私政策》。带内存缓存，供 `runApp` 之前的同步判断复用。
  ///
  /// 读取异常时按「未同意」处理，避免因异常绕过合规门槛。
  static Future<bool> hasConsented() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final agreed = prefs.getBool(_agreedKey) ?? false;
      _cached = agreed;
      return agreed;
    } catch (error, stackTrace) {
      Log.e('读取隐私政策同意状态失败', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  static Future<void> markConsented() async {
    _cached = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_agreedKey, true);
    } catch (error, stackTrace) {
      Log.e('写入隐私政策同意状态失败', error: error, stackTrace: stackTrace);
    }
  }

  @visibleForTesting
  static void resetCacheForTest() => _cached = null;
}
