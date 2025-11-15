import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/services/notification_service.dart';
import 'package:parcel_am/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';
import 'package:parcel_am/core/enums/notification_type.dart';

@GenerateMocks([
  FirebaseMessaging,
  FlutterLocalNotificationsPlugin,
  NotificationRemoteDataSource,
  NavigationService,
  FirebaseAuth,
  User,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
])
import 'notification_service_test.mocks.dart';

void main() {
  late NotificationService notificationService;
  late MockFirebaseMessaging mockMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockNotificationRemoteDataSource mockRemoteDataSource;
  late MockNavigationService mockNavigationService;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockRemoteDataSource = MockNotificationRemoteDataSource();
    mockNavigationService = MockNavigationService();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();

    notificationService = NotificationService(
      firebaseMessaging: mockMessaging,
      localNotifications: mockLocalNotifications,
      remoteDataSource: mockRemoteDataSource,
      navigationService: mockNavigationService,
      firebaseAuth: mockAuth,
      firestore: mockFirestore,
    );
  });

  group('FCM Token Management', () {
    test('should retrieve and return FCM token', () async {
      // Arrange
      const testToken = 'test_fcm_token_123';
      when(mockMessaging.getToken()).thenAnswer((_) async => testToken);

      // Act
      final token = await notificationService.getToken();

      // Assert
      expect(token, testToken);
      verify(mockMessaging.getToken()).called(1);
    });

    test('should store FCM token to Firestore users collection', () async {
      // Arrange
      const userId = 'user_123';
      const token = 'fcm_token_456';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockCollectionRef = MockCollectionReference<Map<String, dynamic>>();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(userId);
      when(mockFirestore.collection('users')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc(userId)).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async => {});

      // Act
      await notificationService.storeToken(token);

      // Assert
      verify(mockDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      })).called(1);
    });
  });

  group('Foreground Notification Handling', () {
    test('should display local notification when receiving FCM message in foreground',
        () async {
      // Arrange
      const userId = 'user_123';
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn(userId);

      final remoteMessage = RemoteMessage(
        messageId: 'msg_123',
        notification: const RemoteNotification(
          title: 'Test Title',
          body: 'Test Body',
        ),
        data: {
          'chatId': 'chat_456',
          'senderId': 'sender_789',
          'senderName': 'John Doe',
          'type': 'chat_message',
        },
        sentTime: DateTime.now(),
      );

      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert
      verify(mockLocalNotifications.show(
        any,
        'Test Title',
        'Test Body',
        any,
        payload: anyNamed('payload'),
      )).called(1);

      verify(mockRemoteDataSource.saveNotification(any)).called(1);
    });
  });

  group('Background Message Handler', () {
    test('should process background message and display local notification',
        () async {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg_background_123',
        data: {
          'title': 'Background Title',
          'body': 'Background Body',
          'chatId': 'chat_999',
          'senderId': 'sender_111',
          'senderName': 'Jane Doe',
          'type': 'chat_message',
        },
        sentTime: DateTime.now(),
      );

      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleBackgroundMessage(remoteMessage);

      // Assert
      verify(mockLocalNotifications.show(
        any,
        'Jane Doe',
        'Background Body',
        any,
        payload: anyNamed('payload'),
      )).called(1);
    });
  });

  group('Notification Tap Handling', () {
    test('should parse payload and navigate to chat screen on notification tap',
        () async {
      // Arrange
      const chatId = 'chat_789';
      final payload = jsonEncode({
        'chatId': chatId,
        'notificationId': 'notif_123',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockNavigationService.navigateTo(any, arguments: anyNamed('arguments')))
          .thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockNavigationService.navigateTo(
        '/chat',
        arguments: anyNamed('arguments'),
      )).called(1);
    });

    test('should handle empty or invalid payload gracefully', () async {
      // Arrange
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: null,
      );

      // Act & Assert - should not throw
      await notificationService.handleNotificationTap(response);

      verifyNever(mockNavigationService.navigateTo(any, arguments: anyNamed('arguments')));
    });
  });

  group('Permission Request', () {
    test('should request notification permissions', () async {
      // Arrange
      final settings = NotificationSettings(
        authorizationStatus: AuthorizationStatus.authorized,
        alert: AppleNotificationSetting.enabled,
        announcement: AppleNotificationSetting.enabled,
        badge: AppleNotificationSetting.enabled,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.enabled,
        notificationCenter: AppleNotificationSetting.enabled,
        showPreviews: AppleShowPreviewSetting.always,
        timeSensitive: AppleNotificationSetting.enabled,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.enabled,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );

      when(mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        announcement: anyNamed('announcement'),
        badge: anyNamed('badge'),
        carPlay: anyNamed('carPlay'),
        criticalAlert: anyNamed('criticalAlert'),
        provisional: anyNamed('provisional'),
        sound: anyNamed('sound'),
      )).thenAnswer((_) async => settings);

      // Act
      final result = await notificationService.requestPermissions();

      // Assert
      expect(result, AuthorizationStatus.authorized);
      verify(mockMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
    });
  });

  group('Helper Methods', () {
    test('should subscribe to FCM topic', () async {
      // Arrange
      const topic = 'test_topic';
      when(mockMessaging.subscribeToTopic(any)).thenAnswer((_) async => {});

      // Act
      await notificationService.subscribeToTopic(topic);

      // Assert
      verify(mockMessaging.subscribeToTopic(topic)).called(1);
    });

    test('should unsubscribe from FCM topic', () async {
      // Arrange
      const topic = 'test_topic';
      when(mockMessaging.unsubscribeFromTopic(any)).thenAnswer((_) async => {});

      // Act
      await notificationService.unsubscribeFromTopic(topic);

      // Assert
      verify(mockMessaging.unsubscribeFromTopic(topic)).called(1);
    });
  });
}
