import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ErrorType {
  authentication,
  network,
  validation,
  session,
  unknown,
}

class AppError {
  final String message;
  final ErrorType type;
  final String? code;
  final dynamic originalError;

  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
  });

  factory AppError.fromFirebaseAuth(FirebaseAuthException error) {
    return AppError(
      message: _getFirebaseAuthMessage(error.code),
      type: ErrorType.authentication,
      code: error.code,
      originalError: error,
    );
  }

  factory AppError.network(String message) {
    return AppError(
      message: message,
      type: ErrorType.network,
    );
  }

  factory AppError.validation(String message) {
    return AppError(
      message: message,
      type: ErrorType.validation,
    );
  }

  factory AppError.session(String message) {
    return AppError(
      message: message,
      type: ErrorType.session,
    );
  }

  factory AppError.unknown(String message) {
    return AppError(
      message: message,
      type: ErrorType.unknown,
    );
  }

  static String _getFirebaseAuthMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Please enter a valid Nigerian phone number';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again';
      case 'session-expired':
        return 'Verification session expired. Please request a new code';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support';
      default:
        return 'An error occurred during authentication. Please try again';
    }
  }
}

class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();
  
  ErrorHandler._();

  /// Show error message to user via SnackBar
  void showError(BuildContext context, AppError error) {
    if (!context.mounted) return;

    final color = _getErrorColor(error.type);
    final icon = _getErrorIcon(error.type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success message to user
  void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info message to user
  void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error dialog for critical errors
  void showErrorDialog(BuildContext context, AppError error) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: _getErrorColor(error.type)),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(error.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle and convert various error types to AppError
  AppError handleError(dynamic error) {
    if (error is FirebaseAuthException) {
      return AppError.fromFirebaseAuth(error);
    } else if (error is AppError) {
      return error;
    } else if (error.toString().contains('network') || 
               error.toString().contains('connection') ||
               error.toString().contains('timeout')) {
      return AppError.network('Network error. Please check your connection and try again');
    } else {
      return AppError.unknown(error.toString());
    }
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
        return Colors.orange;
      case ErrorType.network:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.session:
        return Colors.purple;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.authentication:
        return Icons.security;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.session:
        return Icons.access_time;
      case ErrorType.unknown:
        return Icons.error;
    }
  }
}

/// Extension to easily show errors from any widget
extension ErrorHandlerExtension on BuildContext {
  void showError(AppError error) {
    ErrorHandler.instance.showError(this, error);
  }

  void showErrorMessage(String message) {
    ErrorHandler.instance.showError(this, AppError.unknown(message));
  }

  void showSuccess(String message) {
    ErrorHandler.instance.showSuccess(this, message);
  }

  void showInfo(String message) {
    ErrorHandler.instance.showInfo(this, message);
  }
}