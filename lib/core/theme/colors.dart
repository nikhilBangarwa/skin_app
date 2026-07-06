import 'package:flutter/material.dart';

class AppColors {
  // Mutable static fields to allow dynamic theme switching at runtime
  static Color background = const Color(0xFF0F1115); // Deep space dark
  static Color card = const Color(0xFF1A1D24);       // Sleek charcoal card surface
  static Color primary = const Color(0xFFE89A8D);    // Soft premium rose-gold
  static Color primaryDark = const Color(0xFFD67B6E); // Deeper coral/rose gold for gradients
  static Color accentLight = const Color(0xFF2C2F36); // Light slate for inactive selections
  static Color surface = const Color(0xFF161920);     // Medium dark surface
  static Color textPrimary = const Color(0xFFFFFFFF); // High contrast white
  static Color textSecondary = const Color(0xFFB8B8B8); // Soft muted grey
  static Color divider = const Color(0xFF262A34);     // Soft dark divider
  static Color error = const Color(0xFFE26A6A);       // Premium error red

  // Custom Semantic Colors
  static Color hintText = const Color(0xFF757575);
  static Color cardBackground = const Color(0xFF1A1D24);
  static Color borderColor = const Color(0xFF262A34);
  static Color disabledText = const Color(0xFF9E9E9E);
  static Color secondary = const Color(0xFFD67B6E);

  // Gradients and decorations updated dynamically
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFE89A8D), Color(0xFFD67B6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: const Color(0xFFE89A8D).withValues(alpha: 0.18),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 0),
    ),
  ];

  static Border glassBorder = Border.all(
    color: Colors.white.withValues(alpha: 0.08),
    width: 1.0,
  );

  static Border activeGlassBorder = Border.all(
    color: const Color(0xFFE89A8D).withValues(alpha: 0.4),
    width: 1.5,
  );

  /// Updates the color palette based on active theme
  static void updateTheme(bool isDark) {
    if (isDark) {
      background = const Color(0xFF0F1115);
      card = const Color(0xFF1A1D24);
      primary = const Color(0xFFE89A8D);
      primaryDark = const Color(0xFFD67B6E);
      secondary = const Color(0xFFD67B6E);
      accentLight = const Color(0xFF2C2F36);
      surface = const Color(0xFF161920);
      textPrimary = const Color(0xFFFFFFFF);
      textSecondary = const Color(0xFFB8B8B8);
      hintText = const Color(0xFF757575);
      cardBackground = const Color(0xFF1A1D24);
      borderColor = const Color(0xFF262A34);
      disabledText = const Color(0xFF9E9E9E);
      divider = const Color(0xFF262A34);
      error = const Color(0xFFE26A6A);
    } else {
      background = const Color(0xFFFFFFFF);
      card = const Color(0xFFF8F9FA);
      primary = const Color(0xFFD97B6C);
      primaryDark = const Color(0xFFC05C4F);
      secondary = const Color(0xFFE89A8D);
      accentLight = const Color(0xFFE1E5EB);
      surface = const Color(0xFFF8F9FA);
      textPrimary = const Color(0xFF1A1A1A);
      textSecondary = const Color(0xFF5F6368);
      hintText = const Color(0xFF757575);
      cardBackground = const Color(0xFFF8F9FA);
      borderColor = const Color(0xFFE0E0E0);
      disabledText = const Color(0xFF9E9E9E);
      divider = const Color(0xFFE0E0E0);
      error = const Color(0xFFD9534F);
    }

    primaryGradient = LinearGradient(
      colors: [primary, primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    softShadow = [
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ];

    glowShadow = [
      BoxShadow(
        color: primary.withValues(alpha: 0.18),
        blurRadius: 16,
        spreadRadius: 1,
        offset: const Offset(0, 0),
      ),
    ];

    glassBorder = Border.all(
      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
      width: 1.0,
    );

    activeGlassBorder = Border.all(
      color: primary.withValues(alpha: 0.4),
      width: 1.5,
    );
  }
}
