import 'package:flutter/foundation.dart';
import 'package:ansicolor/ansicolor.dart';

/// Standard log tags for filtering in debug console.
/// Usage: Logger.logBasic('message', tag: LogTag.auth);
/// Filter in console: Search for "[Auth]" or "[Wallet]" etc.
abstract class LogTag {
  static const String auth = 'Auth';
  static const String wallet = 'Wallet';
  static const String chat = 'Chat';
  static const String parcel = 'Parcel';
  static const String notification = 'Notification';
  static const String kyc = 'KYC';
  static const String escrow = 'Escrow';
  static const String network = 'Network';
  static const String firebase = 'Firebase';
  static const String bloc = 'Bloc';
  static const String navigation = 'Navigation';
  static const String storage = 'Storage';
  static const String passkey = 'Passkey';
  static const String totp = 'TOTP';
  static const String withdrawal = 'Withdrawal';
}

enum ColorLogger {
  black,
  red,
  green,
  yellow,
  blue,
  magenta,
  cyan,
  white;

  AnsiPen get _pen {
    switch (this) {
      case ColorLogger.black:
        return AnsiPen()..black();
      case ColorLogger.red:
        return AnsiPen()..red();
      case ColorLogger.green:
        return AnsiPen()..green();
      case ColorLogger.yellow:
        return AnsiPen()..yellow();
      case ColorLogger.blue:
        return AnsiPen()..blue();
      case ColorLogger.magenta:
        return AnsiPen()..magenta();
      case ColorLogger.cyan:
        return AnsiPen()..cyan();
      case ColorLogger.white:
        return AnsiPen()..white();
    }
  }

  void log(dynamic text) {
    if (kDebugMode) {
      print(_pen(text));
    }
  }
}

class Logger {
  static String _formatTag(String? tag) => tag != null ? '[$tag]' : '[App]';

  static void logBasic(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.blue.log("📌 ${_formatTag(tag)} $message");
    }
  }

  static void logError(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.red.log("🚨 ${_formatTag(tag)} $message");
    }
  }

  static void logSuccess(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.green.log("✅ ${_formatTag(tag)} $message");
    }
  }

  static void logWarning(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.yellow.log("⚡ ${_formatTag(tag)} $message");
    }
  }
}
