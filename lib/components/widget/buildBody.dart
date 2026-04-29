import 'package:flutter/material.dart';

class BuildBody extends StatelessWidget {
  const BuildBody({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(padding: EdgeInsetsGeometry.all(16.0), child: child),
    );
  }
}
