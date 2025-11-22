import 'package:flutter/foundation.dart';
import 'package:ansicolor/ansicolor.dart';

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
  static void logBasic(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.blue.log("[ 📌📌📌 ${tag ?? 'No tag'}: $message]");
    }
  }

  static void logError(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.red.log("[ 🚨🚨🚨 ${tag ?? 'No tag'}: $message]");
    }
  }

  static void logSuccess(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.green.log("[✅✅✅ ${tag ?? 'No tag'}: $message]");
    }
  }

  static void logWarning(String message, {String? tag}) {
    if (kDebugMode) {
      ColorLogger.yellow.log("""
        [⚡⚡⚡ ${tag ?? 'No tag'} :$message]""");
    }
  }
}
