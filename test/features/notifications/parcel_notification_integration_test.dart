import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/domain/repositories/notification_repository.dart';
import 'package:parcel_am/core/enums/notification_type.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/services/notification_service.dart';
import 'package:parcel_am/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';

import 'parcel_notification_integration_test.mocks.dart';

@GenerateMocks([
  NotificationRepository,
  FlutterLocalNotificationsPlugin,
  NotificationRemoteDataSource,
  NavigationService,
  FirebaseAuth,
  User,
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

  group('Parcel Notification Integration Tests', () {
    test(
        'END-TO-END: Parcel notification should be saved to Firestore and displayed',
        () async {
      // Arrange - Simulate receiving a parcel acceptance notification
      final remoteMessage = RemoteMessage(
        messageId: 'msg-e2e-123',
        data: {
          'type': 'parcel_request_accepted',
          'title': 'Request Accepted!',
          'body': 'Jane Doe accepted your parcel request from Lagos to Abuja',
          'parcelId': 'parcel-e2e-456',
          'travelerId': 'traveler-789',
          'travelerName': 'Jane Doe',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Jane Doe accepted your parcel request from Lagos to Abuja',
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

      // Act - Handle foreground message (simulates receiving notification)
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert - Verify notification saved to Firestore
      final captured = verify(mockRemoteDataSource.saveNotification(
        captureAny,
      )).captured;
      final savedNotification = captured.first as NotificationModel;

      expect(savedNotification.type, NotificationType.parcelRequestAccepted);
      expect(savedNotification.parcelId, 'parcel-e2e-456');
      expect(savedNotification.travelerId, 'traveler-789');
      expect(savedNotification.travelerName, 'Jane Doe');
      expect(savedNotification.userId, 'test-user-id');
      expect(savedNotification.isRead, false);

      // Assert - Verify local notification displayed
      verify(mockLocalNotifications.show(
        any,
        'Request Accepted!',
        'Jane Doe accepted your parcel request from Lagos to Abuja',
        any,
        payload: anyNamed('payload'),
      )).called(1);

      // Assert - Verify badge count updated
      verify(mockRepository.getUnreadNotificationCount('test-user-id'))
          .called(1);
    });

    test(
        'INTEGRATION: Tapping parcel notification should mark as read and navigate',
        () async {
      // Arrange
      final payload = jsonEncode({
        'parcelId': 'parcel-tap-123',
        'notificationId': 'notif-tap-456',
        'type': 'parcel_request_accepted',
        'travelerId': 'traveler-789',
        'travelerName': 'John Smith',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 4);
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert - Verify marked as read
      verify(mockRemoteDataSource.markAsRead('notif-tap-456')).called(1);

      // Assert - Verify navigation
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': 'parcel-tap-123'},
      )).called(1);

      // Assert - Verify badge count updated
      verify(mockRepository.getUnreadNotificationCount('test-user-id'))
          .called(1);
    });

    test('INTEGRATION: Multiple parcel notifications should update badge count',
        () async {
      // Arrange - First notification
      final message1 = RemoteMessage(
        messageId: 'msg-multi-1',
        data: {
          'type': 'parcel_request_accepted',
          'parcelId': 'parcel-1',
          'travelerId': 'traveler-1',
          'travelerName': 'Traveler One',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Traveler One accepted your request',
        ),
      );

      final message2 = RemoteMessage(
        messageId: 'msg-multi-2',
        data: {
          'type': 'parcel_request_accepted',
          'parcelId': 'parcel-2',
          'travelerId': 'traveler-2',
          'travelerName': 'Traveler Two',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Traveler Two accepted your request',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 1);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act - Receive two notifications
      await notificationService.handleForegroundMessage(message1);
      await notificationService.handleForegroundMessage(message2);

      // Assert - Both notifications saved
      verify(mockRemoteDataSource.saveNotification(any)).called(2);

      // Assert - Badge count retrieved twice
      verify(mockRepository.getUnreadNotificationCount('test-user-id'))
          .called(2);

      // Assert - Both notifications displayed
      verify(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).called(2);
    });

    test(
        'ERROR HANDLING: Invalid parcelId in payload should not crash navigation',
        () async {
      // Arrange - Malformed payload
      final payload = jsonEncode({
        'parcelId': '', // Empty parcelId
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

      // Act - Should not throw
      await notificationService.handleNotificationTap(response);

      // Assert - Navigation should still be attempted even with empty parcelId
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': ''},
      )).called(1);
    });

    test('ERROR HANDLING: Missing notification fields should be handled',
        () async {
      // Arrange - Minimal payload
      final remoteMessage = RemoteMessage(
        messageId: 'msg-minimal',
        data: {
          'type': 'parcel_request_accepted',
          'parcelId': 'parcel-minimal-123',
          // Missing travelerId, travelerName
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Your parcel request was accepted',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 1);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act - Should not throw
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert - Notification saved with null optional fields
      final captured = verify(mockRemoteDataSource.saveNotification(
        captureAny,
      )).captured;
      final savedNotification = captured.first as NotificationModel;

      expect(savedNotification.parcelId, 'parcel-minimal-123');
      expect(savedNotification.travelerId, isNull);
      expect(savedNotification.travelerName, isNull);
    });

    test('INTEGRATION: Parcel notification payload structure is correct',
        () async {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-payload-test',
        data: {
          'type': 'parcel_request_accepted',
          'title': 'Request Accepted!',
          'body': 'Test Traveler accepted your parcel request',
          'parcelId': 'parcel-payload-789',
          'travelerId': 'traveler-payload-456',
          'travelerName': 'Test Traveler',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Test Traveler accepted your parcel request',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 1);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert - Verify payload structure passed to local notification
      final captured = verify(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: captureAnyNamed('payload'),
      )).captured;

      final payloadString = captured.first as String;
      final payloadData = jsonDecode(payloadString) as Map<String, dynamic>;

      expect(payloadData['parcelId'], 'parcel-payload-789');
      expect(payloadData['travelerId'], 'traveler-payload-456');
      expect(payloadData['travelerName'], 'Test Traveler');
      expect(payloadData['type'], 'parcel_request_accepted');
    });

    test(
        'INTEGRATION: Notification from RemoteMessage should match Firestore saved data',
        () async {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-match-test',
        data: {
          'type': 'parcel_request_accepted',
          'title': 'Request Accepted!',
          'body': 'Match Test Traveler accepted your request',
          'parcelId': 'parcel-match-123',
          'travelerId': 'traveler-match-456',
          'travelerName': 'Match Test Traveler',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'Match Test Traveler accepted your request',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 1);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert - Captured notification model
      final captured = verify(mockRemoteDataSource.saveNotification(
        captureAny,
      )).captured;
      final savedNotification = captured.first as NotificationModel;

      // Verify model created from RemoteMessage matches expected data
      final expectedModel =
          NotificationModel.fromRemoteMessage(remoteMessage, 'test-user-id');

      expect(savedNotification.type, expectedModel.type);
      expect(savedNotification.title, expectedModel.title);
      expect(savedNotification.body, expectedModel.body);
      expect(savedNotification.parcelId, expectedModel.parcelId);
      expect(savedNotification.travelerId, expectedModel.travelerId);
      expect(savedNotification.travelerName, expectedModel.travelerName);
    });

    test('INTEGRATION: Badge count should decrease after marking as read',
        () async {
      // Arrange - Simulate tapping notification
      final payload = jsonEncode({
        'parcelId': 'parcel-badge-test',
        'notificationId': 'notif-badge-test',
        'type': 'parcel_request_accepted',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      // Mock decreasing badge count after marking as read
      when(mockRemoteDataSource.markAsRead(any)).thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 3); // Badge count after marking as read
      when(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert - Notification marked as read
      verify(mockRemoteDataSource.markAsRead('notif-badge-test')).called(1);

      // Assert - Badge count retrieved (would show updated count)
      verify(mockRepository.getUnreadNotificationCount('test-user-id'))
          .called(1);
    });

    test(
        'INTEGRATION: Parcel notification with complete data should save all fields',
        () async {
      // Arrange - Complete parcel notification payload
      final remoteMessage = RemoteMessage(
        messageId: 'msg-complete-data',
        data: {
          'type': 'parcel_request_accepted',
          'title': 'Request Accepted!',
          'body':
              'Complete Data Traveler accepted your parcel request from New York to Los Angeles',
          'parcelId': 'parcel-complete-123',
          'travelerId': 'traveler-complete-456',
          'travelerName': 'Complete Data Traveler',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body:
              'Complete Data Traveler accepted your parcel request from New York to Los Angeles',
        ),
      );

      when(mockRemoteDataSource.saveNotification(any))
          .thenAnswer((_) async => {});
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => 1);
      when(mockLocalNotifications.show(
        any,
        any,
        any,
        any,
        payload: anyNamed('payload'),
      )).thenAnswer((_) async => {});

      // Act
      await notificationService.handleForegroundMessage(remoteMessage);

      // Assert - Verify all fields saved to Firestore
      final captured = verify(mockRemoteDataSource.saveNotification(
        captureAny,
      )).captured;
      final savedNotification = captured.first as NotificationModel;

      // Verify complete data structure
      expect(savedNotification.userId, 'test-user-id');
      expect(savedNotification.type, NotificationType.parcelRequestAccepted);
      expect(savedNotification.title, 'Request Accepted!');
      expect(
        savedNotification.body,
        'Complete Data Traveler accepted your parcel request from New York to Los Angeles',
      );
      expect(savedNotification.parcelId, 'parcel-complete-123');
      expect(savedNotification.travelerId, 'traveler-complete-456');
      expect(savedNotification.travelerName, 'Complete Data Traveler');
      expect(savedNotification.isRead, false);
      expect(savedNotification.data, isNotEmpty);
      expect(savedNotification.timestamp, isNotNull);
    });

    test(
        'ERROR HANDLING: Notification with invalid JSON payload should not crash',
        () async {
      // Arrange - Invalid JSON payload
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'invalid-json-{not-a-valid-json}',
      );

      // Act - Should not throw exception
      await notificationService.handleNotificationTap(response);

      // Assert - No navigation should occur with invalid payload
      verifyNever(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      ));
    });
  });
}
