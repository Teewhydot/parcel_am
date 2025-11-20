import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'failure_mapper.dart';
import 'failures.dart';

class FirebaseFailureMapper implements FailureMapper {
  @override
  Failure? map(Object error) {
    if (error is FirebaseAuthException) {
      final message = _getFirebaseAuthMessage(error);
      return AuthFailure(failureMessage: message);
    } else if (error is FirebaseException) {
      final message = _getFirebaseMessage(error);
      return ServerFailure(failureMessage: message);
    }
    return null;
  }

  /// Get user-friendly Firebase Auth error messages
  String _getFirebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'invalid-credential':
        return 'Incorrect login credentials. Please try again';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled. Contact support';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Contact support';
      case 'requires-recent-login':
        return 'Please log in again to continue';
      case 'email-already-verified':
        return 'Email is already verified';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again';
      case 'invalid-verification-id':
        return 'Verification session expired. Please try again';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'Authentication failed. Please try again';
    }
  }

  /// Get user-friendly Firebase error messages
  String _getFirebaseMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action';
      case 'not-found':
        return 'The requested data was not found';
      case 'already-exists':
        return 'This data already exists';
      case 'resource-exhausted':
        return 'Service temporarily unavailable. Please try again';
      case 'failed-precondition':
        return 'Operation cannot be completed at this time';
      case 'aborted':
        return 'Operation was cancelled. Please try again';
      case 'out-of-range':
        return 'Invalid input provided';
      case 'unimplemented':
        return 'This feature is not yet available';
      case 'internal':
        return 'Internal server error. Please try again';
      case 'unavailable':
        return 'Service is temporarily unavailable';
      case 'data-loss':
        return 'Data error occurred. Please try again';
      case 'unauthenticated':
        return 'Please log in to continue';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again';
      case 'cancelled':
        return 'Operation was cancelled';
      default:
        return e.message ?? 'Server error. Please try again';
    }
  }
}
