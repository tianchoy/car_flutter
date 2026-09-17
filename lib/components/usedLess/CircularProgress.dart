import 'package:flutter/cupertino.dart';

class CircularProgress extends StatelessWidget {
  const CircularProgress({
    super.key,
    this.tips = '',
    this.value = '',
    this.label = '',
    required this.diameter,
    required this.circleColor,
  });

  final String tips;
  final String value;
  final String label;
  final Color circleColor;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(diameter),
            painter: _CircularProgressPainter(color: circleColor),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tips,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: diameter * 0.08,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: diameter * 0.2,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: diameter * 0.08,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  const _CircularProgressPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final background = Paint()
      ..color = CupertinoColors.systemGrey5
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, background);

    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      2 * 3.14159 * .8,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.color != color;
}
