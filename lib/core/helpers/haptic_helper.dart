import 'package:vibration/vibration.dart';

/// Helper class for providing haptic feedback throughout the app
class HapticHelper {
  /// Light haptic feedback for general interactions (button taps, selections)
  static Future<void> lightImpact() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 10);
    }
  }

  /// Medium haptic feedback for significant interactions (confirmations, toggles)
  static Future<void> mediumImpact() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 20);
    }
  }

  /// Heavy haptic feedback for important interactions (errors, warnings)
  static Future<void> heavyImpact() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 40);
    }
  }

  /// Success haptic pattern (two quick vibrations)
  static Future<void> success() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 15);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 15);
    }
  }

  /// Error haptic pattern (three short vibrations)
  static Future<void> error() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 20);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 20);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 20);
    }
  }

  /// Selection changed haptic (for sliders, pickers)
  static Future<void> selectionChanged() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 5);
    }
  }
}
