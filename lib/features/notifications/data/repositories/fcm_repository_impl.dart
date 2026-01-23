import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error/error_handler.dart';
import '../../domain/repositories/fcm_repository.dart';

/// Implementation of FCMRepository using Firebase Messaging and Firestore
class FCMRepositoryImpl implements FCMRepository {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;

  FCMRepositoryImpl({
    FirebaseMessaging? firebaseMessaging,
    FirebaseFirestore? firestore,
  })  : _firebaseMessaging = firebaseMessaging ?? GetIt.instance<FirebaseMessaging>(),
        _firestore = firestore ?? GetIt.instance<FirebaseFirestore>();

  @override
  Future<Either<Failure, String?>> getFCMToken() {
    return ErrorHandler.handle(
      () async {
        // On iOS, wait for APNS token before requesting FCM token
        if (Platform.isIOS) {
          // Try to get APNS token first with retry logic
          String? apnsToken;
          int retries = 0;
          const maxRetries = 3;
          const retryDelay = Duration(seconds: 2);

          while (apnsToken == null && retries < maxRetries) {
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken != null) {
              break;
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
      },
      operationName: 'getFCMToken',
    );
  }

  @override
  Future<Either<Failure, void>> storeFCMToken(String userId, String token) {
    return ErrorHandler.handle(
      () async {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      },
      operationName: 'storeFCMToken',
    );
  }

  @override
  Future<Either<Failure, void>> removeFCMToken(String userId, String token) {
    return ErrorHandler.handle(
      () async {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      },
      operationName: 'removeFCMToken',
    );
  }

  @override
  Future<Either<Failure, void>> subscribeToTopic(String topic) {
    return ErrorHandler.handle(
      () async {
        await _firebaseMessaging.subscribeToTopic(topic);
      },
      operationName: 'subscribeToTopic',
    );
  }

  @override
  Future<Either<Failure, void>> unsubscribeFromTopic(String topic) {
    return ErrorHandler.handle(
      () async {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
      },
      operationName: 'unsubscribeFromTopic',
    );
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationCount(String userId) {
    return ErrorHandler.handle(
      () async {
        final snapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        return snapshot.docs.length;
      },
      operationName: 'getUnreadNotificationCount',
    );
  }

  @override
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  @override
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;

  @override
  Future<Either<Failure, AuthorizationStatus>> requestPermissions() {
    return ErrorHandler.handle(
      () async {
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
      },
      operationName: 'requestPermissions',
    );
  }
}
