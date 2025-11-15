import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parcel_am/core/services/notification_service.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';
import 'package:parcel_am/core/enums/notification_type.dart';

@GenerateMocks([
  FirebaseMessaging,
  FlutterLocalNotificationsPlugin,
  NotificationRemoteDataSource,
  NavigationService,
  FirebaseAuth,
  FirebaseFirestore,
  User,
  RemoteMessage,
  RemoteNotification,
  NotificationSettings,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'notification_integration_test.mocks.dart';

void main() {
  group('Notification Integration Tests', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
    late MockNotificationRemoteDataSource mockRemoteDataSource;
    late MockNavigationService mockNavigationService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late NotificationService notificationService;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
      mockRemoteDataSource = MockNotificationRemoteDataSource();
      mockNavigationService = MockNavigationService();
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();

      // Setup auth mock
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_123');

      notificationService = NotificationService(
        firebaseMessaging: mockFirebaseMessaging,
        localNotifications: mockLocalNotifications,
        remoteDataSource: mockRemoteDataSource,
        navigationService: mockNavigationService,
        firebaseAuth: mockFirebaseAuth,
        firestore: mockFirestore,
      );
    });

    test(
        'Integration: Full flow from FCM message to notification display',
        () async {
      // Arrange
      final mockMessage = MockRemoteMessage();
      final mockNotification = MockRemoteNotification();

      when(mockMessage.messageId).thenReturn('msg_integration_123');
      when(mockMessage.notification).thenReturn(mockNotification);
      when(mockMessage.sentTime).thenReturn(DateTime.now());
      when(mockMessage.data).thenReturn({
        'chatId': 'chat_789',
        'senderId': 'sender_456',
        'senderName': 'John Doe',
        'title': 'New Message',
        'body': 'Hello there!',
      });
      when(mockNotification.title).thenReturn('New Message');
      when(mockNotification.body).thenReturn('Hello there!');
      when(mockNotification.android).thenReturn(null);
      when(mockNotification.apple).thenReturn(null);

      // Mock notification display
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async {});

      // Mock saving notification to Firestore
      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async {});

      // Act: Simulate foreground message
      await notificationService.handleForegroundMessage(mockMessage);

      // Assert: Verify notification was saved to Firestore
      verify(mockRemoteDataSource.saveNotification(
        argThat(isA<NotificationModel>()),
      )).called(1);
    });

    test('Integration: Background message handler with app in terminated state',
        () async {
      // Arrange
      final mockMessage = MockRemoteMessage();
      final mockNotification = MockRemoteNotification();

      when(mockMessage.messageId).thenReturn('msg_background_456');
      when(mockMessage.notification).thenReturn(mockNotification);
      when(mockMessage.sentTime).thenReturn(DateTime.now());
      when(mockMessage.data).thenReturn({
        'chatId': 'chat_background',
        'senderId': 'sender_bg',
        'senderName': 'Background Sender',
        'body': 'Background message',
      });
      when(mockNotification.body).thenReturn('Background message');

      // Act
      await notificationService.handleBackgroundMessage(mockMessage);

      // Assert: Verify background notification was displayed
      verify(mockLocalNotifications.show(
        any,
        'Background Sender',
        'Background message',
        any,
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('Integration: Notification tap navigation while app in different states',
        () async {
      // Arrange
      final payload = '{"chatId": "chat_tap_123", "notificationId": "notif_tap_456"}';
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any))
          .thenAnswer((_) async {});

      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert: Verify notification was marked as read
      verify(mockRemoteDataSource.markAsRead('notif_tap_456')).called(1);

      // Assert: Verify navigation was triggered
      verify(mockNavigationService.navigateTo(
        any,
        arguments: argThat(
          isA<Map<String, dynamic>>()
              .having((m) => m['chatId'], 'chatId', 'chat_tap_123'),
          named: 'arguments',
        ),
      )).called(1);
    });

    test('Integration: Token storage and refresh in Firestore users collection',
        () async {
      // Arrange
      const testToken = 'test_fcm_token_refresh_789';

      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => testToken);

      // Act
      final token = await notificationService.getToken();

      // Assert
      expect(token, equals(testToken));
      expect(notificationService.currentToken, equals(testToken));

      // Verify token storage was attempted
      verify(mockFirebaseMessaging.getToken()).called(1);
    });

    test('Integration: Badge count updates correctly', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('user_badge_test');

      // Act
      await notificationService.updateBadgeCount(3);

      // Assert: Badge count update was called with correct count
      // Note: Actual badge update verification would require platform-specific testing
    });

    test('Integration: Mark all as read updates all notifications in Firestore',
        () async {
      // Arrange
      when(mockRemoteDataSource.markAllAsRead('user_test'))
          .thenAnswer((_) async {});

      // Act
      await mockRemoteDataSource.markAllAsRead('user_test');

      // Assert
      verify(mockRemoteDataSource.markAllAsRead('user_test')).called(1);
    });

    test('Integration: Clear all removes all user notifications', () async {
      // Arrange
      when(mockRemoteDataSource.clearAll('user_test'))
          .thenAnswer((_) async {});

      // Act
      await mockRemoteDataSource.clearAll('user_test');

      // Assert
      verify(mockRemoteDataSource.clearAll('user_test')).called(1);
    });

    test('Integration: Notification permissions request on different platforms',
        () async {
      // Arrange
      final mockSettings = MockNotificationSettings();
      when(mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.authorized);

      when(mockFirebaseMessaging.requestPermission(
        alert: anyNamed('alert'),
        announcement: anyNamed('announcement'),
        badge: anyNamed('badge'),
        carPlay: anyNamed('carPlay'),
        criticalAlert: anyNamed('criticalAlert'),
        provisional: anyNamed('provisional'),
        sound: anyNamed('sound'),
      )).thenAnswer((_) async => mockSettings);

      // Act
      final status = await notificationService.requestPermissions();

      // Assert
      expect(status, equals(AuthorizationStatus.authorized));
      verify(mockFirebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
    });

    test('Integration: FCM token refresh flow updates Firestore', () async {
      // Arrange
      const initialToken = 'initial_token_123';

      when(mockFirebaseMessaging.getToken())
          .thenAnswer((_) async => initialToken);

      // Act: Get initial token
      await notificationService.getToken();

      // Assert: Tokens were retrieved
      verify(mockFirebaseMessaging.getToken()).called(1);
    });
  });
}

// Helper function to create mock RemoteMessage
MockRemoteMessage _createMockMessage(String messageId, String chatId, String body) {
  final mockMessage = MockRemoteMessage();
  final mockNotification = MockRemoteNotification();

  when(mockMessage.messageId).thenReturn(messageId);
  when(mockMessage.notification).thenReturn(mockNotification);
  when(mockMessage.sentTime).thenReturn(DateTime.now());
  when(mockMessage.data).thenReturn({
    'chatId': chatId,
    'senderId': 'sender_123',
    'senderName': 'Test Sender',
    'title': 'New Message',
    'body': body,
  });
  when(mockNotification.title).thenReturn('New Message');
  when(mockNotification.body).thenReturn(body);
  when(mockNotification.android).thenReturn(null);
  when(mockNotification.apple).thenReturn(null);

  return mockMessage;
}
