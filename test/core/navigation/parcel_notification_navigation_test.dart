import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/features/notifications/services/notification_service.dart';
import 'package:parcel_am/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parcel_am/features/notifications/domain/repositories/fcm_repository.dart';
import 'package:parcel_am/features/notifications/domain/repositories/notification_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

import 'parcel_notification_navigation_test.mocks.dart';

@GenerateMocks([
  NavigationService,
  FCMRepository,
  NotificationRemoteDataSource,
  NotificationRepository,
  FirebaseAuth,
  User,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService notificationService;
  late MockNavigationService mockNavigationService;
  late MockFCMRepository mockRepository;
  late MockNotificationRemoteDataSource mockRemoteDataSource;
  late MockNotificationRepository mockNotificationRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late FlutterLocalNotificationsPlugin localNotifications;

  setUp(() {
    mockNavigationService = MockNavigationService();
    mockRepository = MockFCMRepository();
    mockRemoteDataSource = MockNotificationRemoteDataSource();
    mockNotificationRepository = MockNotificationRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    localNotifications = FlutterLocalNotificationsPlugin();

    // Register NotificationRepository in GetIt for NotificationUseCase
    final getIt = GetIt.instance;
    if (getIt.isRegistered<NotificationRepository>()) {
      getIt.unregister<NotificationRepository>();
    }
    getIt.registerSingleton<NotificationRepository>(mockNotificationRepository);

    // Setup FirebaseAuth mock
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');

    notificationService = NotificationService(
      repository: mockRepository,
      localNotifications: localNotifications,
      remoteDataSource: mockRemoteDataSource,
      navigationService: mockNavigationService,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<NotificationRepository>()) {
      getIt.unregister<NotificationRepository>();
    }
  });

  group('Parcel Notification Navigation Tests', () {
    test('should navigate to Routes.requestDetails when parcel notification tapped', () async {
      // Arrange
      const parcelId = 'test-parcel-123';
      const notificationId = 'notif-456';

      final payload = jsonEncode({
        'parcelId': parcelId,
        'notificationId': notificationId,
        'type': 'parcel_request_accepted',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(notificationId))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => const Right(0));
      when(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': parcelId},
      )).thenAnswer((_) async => Future.value());

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': parcelId},
      )).called(1);
    });

    test('should pass correct parcelId argument from notification payload', () async {
      // Arrange
      const parcelId = 'parcel-abc-xyz-789';

      final payload = jsonEncode({
        'parcelId': parcelId,
        'type': 'parcel_request_accepted',
        'travelerId': 'traveler-123',
        'travelerName': 'John Doe',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => const Right(0));
      when(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      final captured = verify(mockNavigationService.navigateTo(
        captureAny,
        arguments: captureAnyNamed('arguments'),
      )).captured;

      expect(captured[0], equals(Routes.requestDetails));
      expect(captured[1], isA<Map<String, dynamic>>());
      expect(captured[1]['parcelId'], equals(parcelId));
    });

    test('should navigate to chat when chatId present and no parcelId', () async {
      // Arrange
      const chatId = 'chat-123';

      final payload = jsonEncode({
        'chatId': chatId,
        'type': 'chat_message',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => const Right(0));
      when(mockNavigationService.navigateTo(
        Routes.chat,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockNavigationService.navigateTo(
        Routes.chat,
        arguments: {'chatId': chatId},
      )).called(1);
    });

    test('should prioritize parcelId over chatId when both present', () async {
      // Arrange
      const parcelId = 'parcel-123';
      const chatId = 'chat-456';

      final payload = jsonEncode({
        'parcelId': parcelId,
        'chatId': chatId,
        'type': 'parcel_request_accepted',
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(any))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => const Right(0));
      when(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': parcelId},
      )).called(1);
    });

    test('should mark notification as read before navigation', () async {
      // Arrange
      const parcelId = 'parcel-123';
      const notificationId = 'notif-789';

      final payload = jsonEncode({
        'parcelId': parcelId,
        'notificationId': notificationId,
      });

      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      );

      when(mockRemoteDataSource.markAsRead(notificationId))
          .thenAnswer((_) async => Future.value());
      when(mockRepository.getUnreadNotificationCount(any))
          .thenAnswer((_) async => const Right(0));
      when(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: anyNamed('arguments'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert - verify markAsRead was called
      verify(mockRemoteDataSource.markAsRead(notificationId)).called(1);
      verify(mockNavigationService.navigateTo(
        Routes.requestDetails,
        arguments: {'parcelId': parcelId},
      )).called(1);
    });

    test('should handle empty payload gracefully without navigation', () async {
      // Arrange
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '',
      );

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert - no navigation should occur
      verifyNever(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      ));
    });

    test('should handle null payload gracefully without navigation', () async {
      // Arrange
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: null,
      );

      // Act
      await notificationService.handleNotificationTap(response);

      // Assert - no navigation should occur
      verifyNever(mockNavigationService.navigateTo(
        any,
        arguments: anyNamed('arguments'),
      ));
    });
  });

  group('Route Configuration Verification', () {
    test('Routes.requestDetails should be defined as /requestDetails', () {
      // Verify the route constant is defined correctly
      expect(Routes.requestDetails, equals('/requestDetails'));
    });

    test('Routes.chat should be defined for comparison', () {
      // Verify chat route exists for navigation fallback
      expect(Routes.chat, equals('/chat'));
    });
  });
}
