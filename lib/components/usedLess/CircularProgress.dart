import 'package:flutter/material.dart';

class CircularProgress extends StatelessWidget {
  final String tips;
  final String value;
  final String label;
  final Color circleColor;

  const CircularProgress({
    super.key,
    this.tips = '',
    this.value = '',
    this.label = '',
    required this.circleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            value: 1,
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            color: Colors.grey[300],
            strokeCap: StrokeCap.round,
          ),
        ),
        Transform.rotate(
          angle: 360 * 3.14159 / 180,
          child: SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: 0.8,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              color: circleColor,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tips,
              style: TextStyle(fontSize: 150 * 0.08, color: Colors.black87),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 150 * 0.2,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 150 * 0.08, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }
}
