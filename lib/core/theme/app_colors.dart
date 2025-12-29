import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Primary colors
  static const Color primary = Color(0xFF1B8B5C);
  static const Color primaryLight = Color(0xFF00A86B);
  static const Color primaryDark = Color(0xFF156B47);
  static const Color secondary = Color(0xFF1AC2D9);
  static const Color accent = Color(0xFFFF9500);

  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF166534);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // Additional status colors
  static const Color reversed = Color(0xFF8B5CF6);
  static const Color reversedLight = Color(0xFFEDE9FE);
  static const Color reversedDark = Color(0xFF5B21B6);

  static const Color pending = Color(0xFFF97316);
  static const Color pendingLight = Color(0xFFFFF7ED);
  static const Color pendingDark = Color(0xFFC2410C);

  static const Color processing = Color(0xFF0EA5E9);
  static const Color processingLight = Color(0xFFE0F2FE);
  static const Color processingDark = Color(0xFF0369A1);

  // Surface colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // On colors (text/icons on colored backgrounds)
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF0F172A);
  static const Color onSurface = Color(0xFF475569);
  static const Color onSurfaceVariant = Color(0xFF64748B);

  // Border colors
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Misc colors
  static const Color divider = Color(0xFFE2E8F0);
  static const Color disabled = Color(0xFF94A3B8);
  static const Color shimmer = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryLight],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primaryLight],
  );
}
