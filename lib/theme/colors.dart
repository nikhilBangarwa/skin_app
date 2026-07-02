import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F1115); // Deep space dark
  static const Color card = Color(0xFF1A1D24);       // Sleek charcoal card surface
  static const Color primary = Color(0xFFE89A8D);    // Soft premium rose-gold
  static const Color primaryDark = Color(0xFFD67B6E); // Deeper coral/rose gold for gradients
  static const Color accentLight = Color(0xFF2C2F36); // Light slate for inactive selections
  static const Color surface = Color(0xFF161920);     // Medium dark surface
  static const Color textPrimary = Color(0xFFFFFFFF); // High contrast white
  static const Color textSecondary = Color(0xFFB8B8B8); // Soft muted grey
  static const Color divider = Color(0xFF262A34);     // Soft dark divider
  static const Color error = Color(0xFFE26A6A);       // Premium error red

  // Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  // Subtle Glow Effect on selected components
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.18),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 0),
    ),
  ];

  // Card Borders for premium glassmorphism outline
  static Border glassBorder = Border.all(
    color: Colors.white.withValues(alpha: 0.08),
    width: 1.0,
  );

  static Border activeGlassBorder = Border.all(
    color: primary.withValues(alpha: 0.4),
    width: 1.5,
  );
}
