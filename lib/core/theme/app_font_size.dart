/// Centralized font size constants for the app.
///
/// Use these constants instead of hardcoded font size values.
/// For standard typography, prefer using [TextVariant] in [AppText].
///
/// Standard TextVariant sizes (use these when possible):
/// - labelSmall: 11, labelMedium: 12, labelLarge: 14
/// - bodySmall: 12, bodyMedium: 14, bodyLarge: 16
/// - titleSmall: 14, titleMedium: 16, titleLarge: 22
/// - headlineSmall: 24, headlineMedium: 28, headlineLarge: 32
/// - displaySmall: 36, displayMedium: 45, displayLarge: 57
///
/// Custom sizes (for cases where standard variants don't fit):
/// - xxs: 9 (very small text, badges)
/// - xs: 10 (badges, chips)
/// - sm: 11 (small labels)
/// - md: 13 (between bodySmall and bodyMedium)
/// - lg: 15 (between bodyMedium and bodyLarge)
/// - xl: 18 (emphasized body text, subheadings)
/// - xxl: 20 (large subheadings)
class AppFontSize {
  AppFontSize._();

  // Custom sizes for edge cases
  /// 9.0 - Very small text (badges, status indicators)
  static const double xxs = 9.0;

  /// 10.0 - Extra small (badges, chips, counters)
  static const double xs = 10.0;

  /// 11.0 - Small (matches labelSmall)
  static const double sm = 11.0;

  /// 13.0 - Medium-small (between bodySmall 12 and bodyMedium 14)
  static const double md = 13.0;

  /// 15.0 - Medium-large (between bodyMedium 14 and bodyLarge 16)
  static const double lg = 15.0;

  /// 18.0 - Large (emphasized body, subheadings - between titleMedium 16 and titleLarge 22)
  static const double xl = 18.0;

  /// 20.0 - Extra large (large subheadings - between titleLarge 22 and headlineSmall 24)
  static const double xxl = 20.0;

  // Standard typography sizes (mirrors TextVariant for consistency)
  /// 11.0 - Label small
  static const double labelSmall = 11.0;

  /// 12.0 - Label medium, body small
  static const double labelMedium = 12.0;
  static const double bodySmall = 12.0;

  /// 14.0 - Label large, body medium, title small
  static const double labelLarge = 14.0;
  static const double bodyMedium = 14.0;
  static const double titleSmall = 14.0;

  /// 16.0 - Body large, title medium
  static const double bodyLarge = 16.0;
  static const double titleMedium = 16.0;

  /// 22.0 - Title large
  static const double titleLarge = 22.0;

  /// 24.0 - Headline small
  static const double headlineSmall = 24.0;

  /// 28.0 - Headline medium
  static const double headlineMedium = 28.0;

  /// 32.0 - Headline large
  static const double headlineLarge = 32.0;

  /// 36.0 - Display small
  static const double displaySmall = 36.0;

  /// 45.0 - Display medium
  static const double displayMedium = 45.0;

  /// 57.0 - Display large
  static const double displayLarge = 57.0;
}
