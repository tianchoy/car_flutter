import 'package:flutter/cupertino.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.buildBody,
    this.onClickFunction,
    required this.title,
    this.label = '',
    this.showDivider = false,
  });

  final Widget buildBody;
  final Function? onClickFunction;
  final String title;
  final String? label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      margin: const EdgeInsets.all(10),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.zero,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              CupertinoButton(
                onPressed: () async => onClickFunction?.call(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                minimumSize: Size.zero,
                color: const Color(0xFFF0F9F0),
                borderRadius: BorderRadius.circular(10),
                child: Text(label ?? '', style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          if (showDivider)
            const SizedBox(
              width: double.infinity,
              height: 1,
              child: ColoredBox(color: CupertinoColors.systemGrey5),
            ),
          SizedBox(width: double.infinity, height: 200, child: buildBody),
        ],
      ),
    );
  }
}
