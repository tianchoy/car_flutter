import 'dart:io';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/services/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

/// 协议页以本地 HTML 资源随包分发（原线上路由在后端并不存在），
/// 这里守护「文件存在」与「必备要素齐全」两件事——两者任一缺失都会
/// 直接导致应用市场审核驳回。
String _readAsset(String assetPath) => File(assetPath).readAsStringSync();

void main() {
  group('协议页内置资源', () {
    test('用户协议与隐私政策文件随包存在', () {
      for (final path in <String>[
        LegalLinks.userAgreementAsset,
        LegalLinks.privacyPolicyAsset,
      ]) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path 不存在，审核点开协议将无法显示内容',
        );
      }
    });

    test('协议不再指向失效的线上路由', () {
      final source = _readAsset('lib/services/app_links.dart');
      expect(
        source.contains('gpsapp.zdiot.cn'),
        isFalse,
        reason: '协议内容应使用本地内置资源，线上路由 /privacy-policy 并不存在',
      );
    });

    test('隐私政策包含监管要求的必备要素', () {
      final html = _readAsset(LegalLinks.privacyPolicyAsset);
      const required = <String>[
        '运营主体', // 运营者信息
        '个人信息保护负责人', // 联系方式
        '第三方 SDK', // 第三方 SDK 清单
        '极光推送', // 具体 SDK 名称
        '高德', // 地图服务提供方
        '后台位置信息', // 已保留 ACCESS_BACKGROUND_LOCATION，必须说明用途
        '应用安装列表', // QUERY_ALL_PACKAGES 的用途说明
        '撤回同意', // 用户权利
        '注销账号', // 账号注销途径
        '未成年人', // 儿童条款
      ];
      for (final keyword in required) {
        expect(
          html.contains(keyword),
          isTrue,
          reason: '隐私政策缺少必备要素：$keyword',
        );
      }
    });

    test('用户协议包含必备条款', () {
      final html = _readAsset(LegalLinks.userAgreementAsset);
      const required = <String>['账号注册与使用', '服务内容', '使用规范', '免责', '法律适用', '联系我们'];
      for (final keyword in required) {
        expect(
          html.contains(keyword),
          isTrue,
          reason: '用户协议缺少条款：$keyword',
        );
      }
    });
  });

  group('WebContentRouteArgs 对本地资源的支持', () {
    test('assetPath 生效且不要求 url', () {
      const args = WebContentRouteArgs(
        title: '隐私政策',
        assetPath: 'assets/legal/privacy_policy.html',
      );
      expect(args.hasAsset, isTrue);
      expect(args.trimmedAssetPath, 'assets/legal/privacy_policy.html');
      expect(args.uri, isNull);
    });

    test('非 http(s) 协议的 url 视为无效', () {
      const args = WebContentRouteArgs(title: 'x', url: 'ftp://example.com/a');
      expect(args.uri, isNull);
      expect(args.hasAsset, isFalse);
    });

    test('parse 支持本地资源参数', () {
      final args = WebContentRouteArgs.parse(<String, String>{
        'title': '隐私政策',
        'assetPath': 'assets/legal/privacy_policy.html',
      });
      expect(args, isNotNull);
      expect(args!.hasAsset, isTrue);
      expect(args.url, isNull);
    });

    test('url 与 assetPath 均为空时返回 null', () {
      final args = WebContentRouteArgs.parse(<String, String>{
        'title': 'x',
        'url': '',
        'assetPath': '',
      });
      expect(args, isNull);
    });
  });
}
