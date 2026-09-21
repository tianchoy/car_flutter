import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

/// 地图车标气泡下方统一使用的指向箭头。
///
/// 箭头向下指向同一个 Marker 的车标位置；向上平移 3px，
/// 让箭头顶部压住气泡底边，避免出现白色接缝。
class MapBubbleTail extends StatelessWidget {
  const MapBubbleTail({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -3),
      child: const CustomPaint(
        size: Size(10, 6),
        painter: _MapBubbleTailPainter(),
      ),
    );
  }
}

class _MapBubbleTailPainter extends CustomPainter {
  const _MapBubbleTailPainter();

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()
      ..color = CupertinoColors.white
      ..style = ui.PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MapBubbleTailPainter oldDelegate) => false;
}
