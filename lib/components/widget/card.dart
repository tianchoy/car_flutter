import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget buildBody;
  final Function? onClickFunction;
  final String title;
  final String? label;
  final bool showDivider;

  const CustomCard({
    super.key,
    required this.buildBody,
    this.onClickFunction,
    required this.title,
    this.label = '',
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
      margin: EdgeInsets.all(10.0),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  onClickFunction?.call();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF0F9F0),
                  foregroundColor: Color(0xFF07C160),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  minimumSize: Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(label!, style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          if (showDivider)
            Divider(color: Colors.grey[100], height: 1, thickness: 1),
          SizedBox(width: double.infinity, height: 200, child: buildBody),
        ],
      ),
    );
  }
}
