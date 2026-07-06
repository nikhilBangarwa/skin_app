import 'package:flutter/material.dart';

class SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;

  SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double widthStep = size.width / (points.length - 1);
    
    // Start point
    path.moveTo(0, size.height - (points[0] * size.height));

    // Draw smooth bezier curves between points
    for (int i = 0; i < points.length - 1; i++) {
      final double x1 = i * widthStep;
      final double y1 = size.height - (points[i] * size.height);
      final double x2 = (i + 1) * widthStep;
      final double y2 = size.height - (points[i + 1] * size.height);
      
      final double cx1 = x1 + (widthStep / 2);
      final double cy1 = y1;
      final double cx2 = x1 + (widthStep / 2);
      final double cy2 = y2;
      
      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    // Draw main line path
    canvas.drawPath(path, paint);

    // Create a closed path for gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw gradient fill
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
