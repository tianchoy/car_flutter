import 'package:flutter/cupertino.dart';

class BuildBody extends StatelessWidget {
  const BuildBody({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
