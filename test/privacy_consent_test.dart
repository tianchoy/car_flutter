import 'package:car/services/privacy_consent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 隐私政策同意状态是合规门槛：未同意时不得初始化任何采集类 SDK。
/// 这里守护「默认未同意」与「同意后可持久化」两条关键行为。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PrivacyConsentService.resetCacheForTest();
  });

  test('首次启动（无记录）视为未同意', () async {
    expect(await PrivacyConsentService.hasConsented(), isFalse);
  });

  test('同意后状态为已同意，且可跨进程从持久化恢复', () async {
    await PrivacyConsentService.markConsented();
    expect(await PrivacyConsentService.hasConsented(), isTrue);

    // 清掉内存缓存，模拟下次冷启动
    PrivacyConsentService.resetCacheForTest();
    expect(await PrivacyConsentService.hasConsented(), isTrue);
  });

  test('持久化中已为 true 时直接返回已同意', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'legal.privacy_policy_agreed.v1': true,
    });
    PrivacyConsentService.resetCacheForTest();
    expect(await PrivacyConsentService.hasConsented(), isTrue);
  });

  test('持久化为 false 时视为未同意', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'legal.privacy_policy_agreed.v1': false,
    });
    PrivacyConsentService.resetCacheForTest();
    expect(await PrivacyConsentService.hasConsented(), isFalse);
  });
}
