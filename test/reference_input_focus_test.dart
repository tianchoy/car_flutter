import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car/widgets/reference_ui.dart';

void main() {
  testWidgets('校验提示出现 / 消失时输入框都不丢失焦点', (tester) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final errorNotifier = ValueNotifier<String>('');

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Column(
            children: [
              ReferenceInput(controller: oldController, hint: '当前密码'),
              ValueListenableBuilder<String>(
                valueListenable: errorNotifier,
                builder: (context, error, child) => ReferenceInput(
                  controller: newController,
                  hint: '新密码',
                  errorText: error,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 聚焦第二个输入框（对应「新密码」）并输入。
    await tester.tap(find.byType(CupertinoTextField).at(1));
    await tester.pump();
    await tester.enterText(find.byType(CupertinoTextField).at(1), 'a');
    await tester.pump();

    FocusNode currentFocusNode() => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byType(CupertinoTextField).at(1),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode;

    expect(currentFocusNode().hasFocus, isTrue);

    // 校验提示出现：输入框结构不能因此被重建。
    errorNotifier.value = '密码需为 8–16 位，且包含至少两种字符类型';
    await tester.pump();
    expect(currentFocusNode().hasFocus, isTrue, reason: '校验提示出现后焦点应保持在原输入框');

    // 校验提示消失：同样不能丢焦点。
    errorNotifier.value = '';
    await tester.pump();
    expect(currentFocusNode().hasFocus, isTrue, reason: '校验提示消失后焦点应保持在原输入框');
  });
}
