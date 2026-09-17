import 'package:flutter/cupertino.dart';

class BuildContainer extends StatelessWidget {
  const BuildContainer({
    super.key,
    this.child,
    this.color = CupertinoColors.white,
  });

  final Widget? child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }
}
