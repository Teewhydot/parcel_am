import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/repositories/fcm_repository.dart';

/// Implementation of FCMRepository using Firebase Messaging and Firestore
class FCMRepositoryImpl implements FCMRepository {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;

  FCMRepositoryImpl({
    required FirebaseMessaging firebaseMessaging,
    required FirebaseFirestore firestore,
  })  : _firebaseMessaging = firebaseMessaging,
        _firestore = firestore;

  @override
  Future<String?> getFCMToken() async {
    try {
      // On iOS, wait for APNS token before requesting FCM token
      if (Platform.isIOS) {
        // Try to get APNS token first with retry logic
        String? apnsToken;
        int retries = 0;
        const maxRetries = 3;
        const retryDelay = Duration(seconds: 2);

        while (apnsToken == null && retries < maxRetries) {
          try {
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              break;
            }
          } catch (e) {
            // Silent catch
          }

          retries++;
          if (retries < maxRetries && apnsToken == null) {
            await Future.delayed(retryDelay);
          }
        }

        // If APNS token is still not available after retries, return null
        if (apnsToken == null) {
          return null;
        }
      }

      // Get FCM token
      return await _firebaseMessaging.getToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> storeFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // Silent catch
    }
  }

  @override
  Future<void> removeFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      // Silent catch
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  @override
  Future<AuthorizationStatus> requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus;
  }
}
