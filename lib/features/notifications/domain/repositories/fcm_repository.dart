import 'package:firebase_messaging/firebase_messaging.dart';

/// Repository interface for Firebase Cloud Messaging operations
abstract class FCMRepository {
  /// Get the current FCM token for this device
  Future<String?> getFCMToken();

  /// Store FCM token to Firestore users/{userId}/fcmTokens array
  Future<void> storeFCMToken(String userId, String token);

  /// Remove FCM token from Firestore (e.g., on logout)
  Future<void> removeFCMToken(String userId, String token);

  /// Subscribe to an FCM topic for broadcast messages
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from an FCM topic
  Future<void> unsubscribeFromTopic(String topic);

  /// Get count of unread notifications for a user
  Future<int> getUnreadNotificationCount(String userId);

  /// Stream of token refresh events
  Stream<String> get onTokenRefresh;

  /// Stream of foreground FCM messages
  Stream<RemoteMessage> get onForegroundMessage;

  /// Request notification permissions (iOS/web)
  Future<AuthorizationStatus> requestPermissions();
}
