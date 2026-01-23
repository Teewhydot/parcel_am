import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/errors/failures.dart';

/// Repository interface for Firebase Cloud Messaging operations
abstract class FCMRepository {
  /// Get the current FCM token for this device
  Future<Either<Failure, String?>> getFCMToken();

  /// Store FCM token to Firestore users/{userId}/fcmTokens array
  Future<Either<Failure, void>> storeFCMToken(String userId, String token);

  /// Remove FCM token from Firestore (e.g., on logout)
  Future<Either<Failure, void>> removeFCMToken(String userId, String token);

  /// Subscribe to an FCM topic for broadcast messages
  Future<Either<Failure, void>> subscribeToTopic(String topic);

  /// Unsubscribe from an FCM topic
  Future<Either<Failure, void>> unsubscribeFromTopic(String topic);

  /// Get count of unread notifications for a user
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId);

  /// Stream of token refresh events
  Stream<String> get onTokenRefresh;

  /// Stream of foreground FCM messages
  Stream<RemoteMessage> get onForegroundMessage;

  /// Request notification permissions (iOS/web)
  Future<Either<Failure, AuthorizationStatus>> requestPermissions();
}
