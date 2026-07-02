import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

// --- ANIMATED SCANNING FACE ILLUSTRATION (Step 1) ---
class ScanFaceIllustration extends StatefulWidget {
  const ScanFaceIllustration({super.key});

  @override
  State<ScanFaceIllustration> createState() => _ScanFaceIllustrationState();
}

class _ScanFaceIllustrationState extends State<ScanFaceIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 180),
          painter: _FaceScanPainter(_controller.value),
        );
      },
    );
  }
}

class _FaceScanPainter extends CustomPainter {
  final double scanProgress;

  _FaceScanPainter(this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Draw scanning grid boundaries (Hexagon or stylized circle)
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = i * math.pi / 3;
      double x = cx + 80 * math.cos(angle);
      double y = cy + 80 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Draw inner face scan placeholder contour
    final facePath = Path();
    facePath.moveTo(cx - 30, cy - 40);
    // Forehead
    facePath.cubicTo(cx - 50, cy - 40, cx - 50, cy - 20, cx - 50, cy);
    // Cheek & Jawline
    facePath.cubicTo(cx - 50, cy + 30, cx - 30, cy + 50, cx, cy + 55);
    facePath.cubicTo(cx + 30, cy + 50, cx + 50, cy + 30, cx + 50, cy);
    // Forehead right
    facePath.cubicTo(cx + 50, cy - 20, cx + 50, cy - 40, cx + 30, cy - 40);
    facePath.close();

    canvas.drawPath(facePath, paint);

    // Feature keypoints
    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(cx - 20, cy - 10), 3, pointPaint); // Left Eye
    canvas.drawCircle(Offset(cx + 20, cy - 10), 3, pointPaint); // Right Eye
    canvas.drawCircle(Offset(cx, cy + 10), 3, pointPaint);      // Nose
    canvas.drawCircle(Offset(cx, cy + 30), 2.5, pointPaint);    // Mouth

    // Draw scanning line
    double scanY = cy - 80 + 160 * scanProgress;
    
    // Laser glow line
    canvas.drawLine(Offset(cx - 90, scanY), Offset(cx + 90, scanY), glowPaint);
    canvas.drawLine(Offset(cx - 80, scanY), Offset(cx + 80, scanY), linePaint);

    // Connect scan intersections
    canvas.drawCircle(Offset(cx - 35, scanY), 4, pointPaint..color = Colors.white);
    canvas.drawCircle(Offset(cx + 35, scanY), 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceScanPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}


// --- ANIMATED SKIN LAYERS HYDRATION DIAGRAM (Step 2) ---
class SkinLayersIllustration extends StatefulWidget {
  const SkinLayersIllustration({super.key});

  @override
  State<SkinLayersIllustration> createState() => _SkinLayersIllustrationState();
}

class _SkinLayersIllustrationState extends State<SkinLayersIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 160),
          painter: _SkinLayersPainter(_controller.value),
        );
      },
    );
  }
}

class _SkinLayersPainter extends CustomPainter {
  final double animationVal;

  _SkinLayersPainter(this.animationVal);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paints
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final lipidPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Draw 3 layers of skin cells
    // Layer 1: Stratum corneum (wavy curve)
    final pathLayer1 = Path();
    pathLayer1.moveTo(0, h * 0.35);
    for (double i = 0; i <= w; i += 20) {
      double wave = 4 * math.sin((i / w * 4 * math.pi) + (animationVal * 2 * math.pi));
      pathLayer1.lineTo(i, h * 0.35 + wave);
    }
    pathLayer1.lineTo(w, h);
    pathLayer1.lineTo(0, h);
    pathLayer1.close();
    
    // Draw Layer 2 background
    canvas.drawRect(Rect.fromLTRB(0, h * 0.55, w, h), Paint()..color = const Color(0xFF1E222B));
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), borderPaint);

    // Draw Layer 3 background
    canvas.drawRect(Rect.fromLTRB(0, h * 0.78, w, h), Paint()..color = const Color(0xFF262C36));
    canvas.drawLine(Offset(0, h * 0.78), Offset(w, h * 0.78), borderPaint);

    // Draw top moisture barrier
    final barrierPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final barrierPath = Path();
    barrierPath.moveTo(0, h * 0.35);
    for (double i = 0; i <= w; i += 10) {
      double wave = 4 * math.sin((i / w * 4 * math.pi) + (animationVal * 2 * math.pi));
      barrierPath.lineTo(i, h * 0.35 + wave);
    }
    canvas.drawPath(barrierPath, barrierPaint);

    // Draw cells (overlapping capsules) in the middle layer
    for (double x = 15; x < w; x += 35) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, h * 0.45), width: 30, height: 18),
          const Radius.circular(6),
        ),
        lipidPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + 15, h * 0.65), width: 30, height: 18),
          const Radius.circular(6),
        ),
        lipidPaint..color = AppColors.primary.withValues(alpha: 0.15),
      );
    }

    // Draw animated floating water molecules (droplets/particles)
    final moleculePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      double offsetFactor = (i * 0.2);
      double progress = (animationVal + offsetFactor) % 1.0;
      
      double px = w * (0.15 + (i * 0.18));
      double py = h * 0.9 - (h * 0.55 * progress);
      double sizeFactor = 3 * (1.0 - progress);

      // Droplet shape
      final dropPath = Path();
      dropPath.moveTo(px, py - sizeFactor);
      dropPath.cubicTo(px - sizeFactor, py, px - sizeFactor, py + sizeFactor, px, py + sizeFactor);
      dropPath.cubicTo(px + sizeFactor, py + sizeFactor, px + sizeFactor, py, px, py - sizeFactor);
      dropPath.close();

      canvas.drawPath(dropPath, moleculePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SkinLayersPainter oldDelegate) {
    return oldDelegate.animationVal != animationVal;
  }
}


// --- ANIMATED HEXAGON ANALYSIS GRID (Step 3) ---
class AnalysisGridIllustration extends StatefulWidget {
  const AnalysisGridIllustration({super.key});

  @override
  State<AnalysisGridIllustration> createState() => _AnalysisGridIllustrationState();
}

class _AnalysisGridIllustrationState extends State<AnalysisGridIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 160),
          painter: _AnalysisGridPainter(_controller.value),
        );
      },
    );
  }
}

class _AnalysisGridPainter extends CustomPainter {
  final double animationVal;

  _AnalysisGridPainter(this.animationVal);

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double angle = i * math.pi / 3;
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final activePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double hexRadius = 24.0;
    final double hSpacing = hexRadius * math.sqrt(3);
    final double vSpacing = hexRadius * 1.5;

    // Draw central grid of hexagons
    for (int row = -2; row <= 2; row++) {
      for (int col = -2; col <= 2; col++) {
        double xOffset = (row % 2 != 0) ? hSpacing / 2 : 0;
        double hX = cx + col * hSpacing + xOffset;
        double hY = cy + row * vSpacing;

        // Animate grid pulse outward
        double dist = math.sqrt(math.pow(hX - cx, 2) + math.pow(hY - cy, 2));
        double maxDist = hexRadius * 3;
        double wave = math.sin((dist / maxDist * math.pi) - (animationVal * 2 * math.pi));
        
        if (wave > 0.6) {
          activePaint.color = AppColors.primary.withValues(alpha: (wave - 0.6) * 1.5);
          _drawHexagon(canvas, Offset(hX, hY), hexRadius, activePaint);
        } else {
          _drawHexagon(canvas, Offset(hX, hY), hexRadius, linePaint);
        }
      }
    }

    // Central target ring
    final targetPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(cx, cy), 12 + 6 * math.sin(animationVal * 2 * math.pi), targetPaint..color = AppColors.primary.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _AnalysisGridPainter oldDelegate) {
    return oldDelegate.animationVal != animationVal;
  }
}
