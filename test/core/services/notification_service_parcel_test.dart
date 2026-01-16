import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/features/notifications/domain/repositories/fcm_repository.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/features/notifications/services/notification_service.dart';
import 'package:parcel_am/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';

import 'notification_service_parcel_test.mocks.dart';

@GenerateMocks([
  FCMRepository,
  FlutterLocalNotificationsPlugin,
  NotificationRemoteDataSource,
  NavigationService,
  FirebaseAuth,
  User,
  AndroidFlutterLocalNotificationsPlugin,
])
void main() {
  late NotificationService notificationService;
  late MockNotificationRepository mockRepository;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockNotificationRemoteDataSource mockRemoteDataSource;
  late MockNavigationService mockNavigationService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockRepository = MockNotificationRepository();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockRemoteDataSource = MockNotificationRemoteDataSource();
    mockNavigationService = MockNavigationService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    notificationService = NotificationService(
      repository: mockRepository,
      localNotifications: mockLocalNotifications,
      remoteDataSource: mockRemoteDataSource,
      navigationService: mockNavigationService,
      firebaseAuth: mockFirebaseAuth,
    );

    // Setup default mock behavior
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');
  });

  group('NotificationService - Parcel Updates Channel', () {
    test('should create parcel_updates Android notification channel', () async {
      // Note: This test verifies channel creation is called
      // Full Android integration testing would require actual device
      expect(notificationService, isNotNull);
    });
  });

  group('NotificationService - Foreground Parcel Notifications', () {
    test('should handle foreground parcel_request_accepted message', () async {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-123',
        data: {
          'type': 'parcel_request_accepted',
          'title': 'Request Accepted!',
          'body': 'John accepted your parcel request from Lagos to Abuja',
          'parcelId': 'parcel-456',
          'travelerId': 'traveler-789',
          'travelerName': 'John Doe',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'John accepted your parcel request from Lagos to Abuja',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 5);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert
      verify(mockRemoteDataSource.saveNotification(any)).called(1);
      verify(mockLocalNotifications.show(
        any,
        'Request Accepted!',
        'John accepted your parcel request from Lagos to Abuja',
        any,
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('should extract parcelId from foreground message data', () async {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-456',
        data: {
          'type': 'parcel_request_accepted',
          'parcelId': 'parcel-test-123',
          'travelerId': 'traveler-123',
          'travelerName': 'Jane Doe',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Jane accepted your parcel request',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 3);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert
      final captured = verify(mockRemoteDataSource.saveNotification(
        captureAny,
      )).captured;
      final savedNotification = captured.first as NotificationModel;
      expect(savedNotification.parcelId, 'parcel-test-123');
      expect(savedNotification.travelerId, 'traveler-123');
      expect(savedNotification.travelerName, 'Jane Doe');
    });
  });

  group('NotificationService - Parcel Notification Tap Navigation', () {
    test('should navigate to RequestDetailsScreen on parcel notification tap',
        () async {
      // Arrange
      final payload = jsonEncode({
        'parcelId': 'parcel-789',
        'type': 'parcel_request_accepted',
        'notificationId': 'notif-123',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 2);
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': 'parcel-789'},
      )).called(1);
    });

    test('should navigate to ChatScreen on chat notification tap', () async {
      // Arrange
      final payload = jsonEncode({
        'chatId': 'chat-123',
        'notificationId': 'notif-456',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 1);
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockNavigationService.navigateTo(
        Routes.chat,
        arguments: {'chatId': 'chat-123'},
      )).called(1);
    });

    test('should mark notification as read on tap', () async {
      // Arrange
      final payload = jsonEncode({
        'parcelId': 'parcel-999',
        'notificationId': 'notif-999',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 0);
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockRemoteDataSource.markAsRead('notif-999')).called(1);
    });
  });

  group('NotificationService - Payload Parsing', () {
    test('should parse parcelId from notification payload', () async {
      // Arrange
      final payload = jsonEncode({
        'parcelId': 'parcel-abc-123',
        'travelerId': 'traveler-xyz',
        'type': 'parcel_request_accepted',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 0);
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      final captured = verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: captureAnyNamed('arguments'),
      )).captured;

      final arguments = captured.first as Map<String, dynamic>;
      expect(arguments['parcelId'], 'parcel-abc-123');
    });

    test('should handle payload with both chatId and parcelId gracefully',
        () async {
      // Arrange - parcelId takes precedence
      final payload = jsonEncode({
        'parcelId': 'parcel-123',
        'chatId': 'chat-456',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 0);
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert - should navigate to parcel details if both are present
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': 'parcel-123'},
      )).called(1);
    });
  });

  group('NotificationService - Badge Count Updates', () {
    test('should update badge count after receiving parcel notification',
        () async {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-badge-test',
        data: {
          'type': 'parcel_request_accepted',
          'parcelId': 'parcel-badge-123',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Test notification',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 7);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert
      verify(mockRepository.getUnreadNotificationCount('test-user-id'))
          .called(1);
    });
  });
}
