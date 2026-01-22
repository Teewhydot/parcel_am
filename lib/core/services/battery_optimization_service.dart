import 'dart:io';
import 'package:flutter/material.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle battery optimization settings for reliable background notifications.
///
/// Android manufacturers (especially Xiaomi, Huawei, Samsung, Oppo, OnePlus) have
/// aggressive battery optimization that can prevent background notifications from
/// working when the app is terminated.
///
/// This service helps guide users to disable battery optimization for the app.
class BatteryOptimizationService {
  static const String _prefKeyOptimizationPromptShown =
      'battery_optimization_prompt_shown';
  static const String _prefKeyOptimizationDismissedAt =
      'battery_optimization_dismissed_at';
  static const int _promptCooldownDays = 7;

  /// Check if battery optimization is currently disabled for the app.
  /// Returns true if optimizations are disabled (good for notifications).
  /// Returns null if check fails or not supported.
  static Future<bool?> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true; // iOS doesn't have this issue

    try {
      return await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    } catch (e) {
      return null;
    }
  }

  /// Check if auto-start is enabled for the app.
  /// This is important for manufacturers like Xiaomi, Huawei, etc.
  static Future<bool?> isAutoStartEnabled() async {
    if (!Platform.isAndroid) return true;

    try {
      return await DisableBatteryOptimization.isAutoStartEnabled;
    } catch (e) {
      return null;
    }
  }

  /// Request the user to disable battery optimization.
  /// Shows a system dialog on supported devices.
  static Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await DisableBatteryOptimization
          .showDisableBatteryOptimizationSettings();
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Show manufacturer-specific auto-start settings.
  /// Important for Xiaomi, Huawei, Oppo, OnePlus, etc.
  static Future<bool> showAutoStartSettings() async {
    if (!Platform.isAndroid) return true;

    try {
      final result =
          await DisableBatteryOptimization.showEnableAutoStartSettings(
        'Enable Auto-Start',
        'To receive notifications when the app is closed, please enable auto-start for this app.',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Show all battery optimization and auto-start settings at once.
  static Future<void> showAllBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;

    try {
      // First show battery optimization settings
      await DisableBatteryOptimization
          .showDisableBatteryOptimizationSettings();

      // Then show auto-start settings for OEM devices
      await DisableBatteryOptimization.showEnableAutoStartSettings(
        'Enable Auto-Start',
        'To ensure you receive notifications when the app is closed, '
            'please enable auto-start for this app.\n\n'
            'This is especially important on Xiaomi, Huawei, Oppo, and OnePlus devices.',
      );
    } catch (e) {
      // Silent catch
    }
  }

  /// Check if we should show the optimization prompt to the user.
  /// Returns true if:
  /// - On Android
  /// - Battery optimization is NOT already disabled
  /// - We haven't shown the prompt recently (cooldown period)
  static Future<bool> shouldShowOptimizationPrompt() async {
    if (!Platform.isAndroid) return false;

    try {
      // Check if optimization is already disabled
      final isDisabled = await isBatteryOptimizationDisabled();
      if (isDisabled == true) return false;

      // Check cooldown period
      final prefs = await SharedPreferences.getInstance();
      final dismissedAt = prefs.getInt(_prefKeyOptimizationDismissedAt);

      if (dismissedAt != null) {
        final dismissedDate =
            DateTime.fromMillisecondsSinceEpoch(dismissedAt);
        final daysSinceDismissed =
            DateTime.now().difference(dismissedDate).inDays;

        if (daysSinceDismissed < _promptCooldownDays) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark that the user dismissed the optimization prompt.
  /// This starts the cooldown period before showing it again.
  static Future<void> markPromptDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _prefKeyOptimizationDismissedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setBool(_prefKeyOptimizationPromptShown, true);
    } catch (e) {
      // Silent catch
    }
  }

  /// Show a custom dialog explaining battery optimization to the user.
  /// Returns true if user chose to optimize, false if dismissed.
  static Future<bool> showOptimizationDialog(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notification Settings',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To receive chat notifications when the app is closed, '
                'please optimize battery settings for this app.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'What this does:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              _BulletPoint(text: 'Allows notifications when app is closed'),
              _BulletPoint(text: 'Prevents your device from stopping the app'),
              _BulletPoint(text: 'Minimal impact on battery life'),
              SizedBox(height: 16),
              Text(
                'Note: Some devices (Xiaomi, Huawei, etc.) may require '
                'additional auto-start settings.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Optimize'),
          ),
        ],
      ),
    );

    if (result == true) {
      await showAllBatteryOptimizationSettings();
      return true;
    } else {
      await markPromptDismissed();
      return false;
    }
  }

  /// Convenience method to check and prompt for optimization.
  /// Call this after user logs in or on app startup.
  static Future<void> checkAndPromptOptimization(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final shouldShow = await shouldShowOptimizationPrompt();
    if (shouldShow && context.mounted) {
      await showOptimizationDialog(context);
    }
  }
}

/// Simple bullet point widget for the dialog.
class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
