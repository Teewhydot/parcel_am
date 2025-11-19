import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationRepository {
  Future<String?> getFCMToken();
  Future<void> storeFCMToken(String userId, String token);
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<int> getUnreadNotificationCount(String userId);
  Stream<String> get onTokenRefresh;
  Stream<RemoteMessage> get onForegroundMessage;
  Future<AuthorizationStatus> requestPermissions();
}
