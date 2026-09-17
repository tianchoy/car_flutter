import 'package:car/shared/services/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the reference user agreement in a dismissible dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => LegalLinks.showUserAgreement(context),
            child: const Text('打开用户协议'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开用户协议'));
    await tester.pumpAndSettle();

    expect(find.text('用户协议'), findsOneWidget);
    expect(find.textContaining('服务条款的确认和接纳'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    expect(find.text('用户协议'), findsNothing);
  });

  testWidgets('shows the reference privacy policy in a dismissible dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => LegalLinks.showPrivacyPolicy(context),
            child: const Text('打开隐私政策'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开隐私政策'));
    await tester.pumpAndSettle();

    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.textContaining('信息收集'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    expect(find.text('隐私政策'), findsNothing);
  });
}
