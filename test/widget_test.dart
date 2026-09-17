import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

class CounterDemo extends StatefulWidget {
  const CounterDemo({super.key});

  @override
  State<CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<CounterDemo> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('计数')),
        child: Stack(
          children: [
            Center(child: Text('$count')),
            Positioned(
              right: 16,
              bottom: 16,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.all(14),
                onPressed: () => setState(() => count++),
                child: const Icon(CupertinoIcons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('counter smoke test', (tester) async {
    await tester.pumpWidget(const CounterDemo());

    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
