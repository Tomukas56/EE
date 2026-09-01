import 'package:flutter/material.dart';

/// Compact Google "G" mark so we do not depend on the placeholder PNG.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.18;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: s / 2 - stroke / 2,
    );
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    sweep.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.35, 1.55, false, sweep);
    sweep.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.20, 1.05, false, sweep);
    sweep.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.25, 0.85, false, sweep);
    sweep.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.10, 1.35, false, sweep);

    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke * 0.2, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
