import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';

class AmbientGlowBackground extends StatelessWidget {
  final Widget child;

  const AmbientGlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark color
        Container(
          color: AppColors.background,
        ),
        
        // Glowing Orb 1 (Top Left)
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ),

        // Glowing Orb 2 (Middle Right)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD67B6E).withValues(alpha: 0.08),
            ),
          ),
        ),

        // Glowing Orb 3 (Bottom Left)
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
          ),
        ),

        // Blur Filter to turn the orbs into soft glowing clouds
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Main screen content on top
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
