// المسار: lib/widgets/radar_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  final double str, spd, def, skl;
  final double maxStat;

  RadarPainter({required this.str, required this.spd, required this.def, required this.skl})
      : maxStat = [str, spd, def, skl, 10.0].reduce(max);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final bgPaint = Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), bgPaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), bgPaint);
    for(int i=1; i<=4; i++) { canvas.drawCircle(center, radius * (i/4), bgPaint); }

    final path = Path();
    path.moveTo(center.dx, center.dy - (radius * (str / maxStat)));
    path.lineTo(center.dx + (radius * (skl / maxStat)), center.dy);
    path.lineTo(center.dx, center.dy + (radius * (def / maxStat)));
    path.lineTo(center.dx - (radius * (spd / maxStat)), center.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.amber.withOpacity(0.4)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}