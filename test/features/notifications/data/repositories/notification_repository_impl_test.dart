import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/enums/notification_type.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/core/network/network_info.dart';
import 'package:parcel_am/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';
import 'package:parcel_am/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:parcel_am/features/notifications/domain/entities/notification_entity.dart';

@GenerateMocks([NotificationRemoteDataSource, NetworkInfo])
import 'notification_repository_impl_test.mocks.dart';

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockNotificationRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = NotificationRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('NotificationRepositoryImpl', () {
    final testTimestamp = DateTime(2025, 11, 14, 10, 30);
    final testNotificationModel = NotificationModel(
      id: 'notif123',
      userId: 'user789',
      type: NotificationType.chatMessage,
      title: 'New Message',
      body: 'John Doe sent you a message',
      data: {'chatId': 'chat123'},
      timestamp: testTimestamp,
      isRead: false,
      chatId: 'chat123',
      senderId: 'user456',
      senderName: 'John Doe',
    );

    final testNotificationList = [testNotificationModel];

    group('watchNotifications', () {
      test('should return stream of user-specific notifications when connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.watchNotifications('user789'))
            .thenAnswer((_) => Stream.value(testNotificationList));

        // Act
        final result = repository.watchNotifications('user789');

        // Assert
        final emittedValue = await result.first;
        expect(emittedValue.isRight(), true);
        emittedValue.fold(
          (failure) => fail('Should not emit failure'),
          (notifications) {
            expect(notifications, testNotificationList);
            expect(notifications.length, 1);
            expect(notifications[0].id, 'notif123');
            expect(notifications[0].userId, 'user789');
          },
        );
        verify(mockNetworkInfo.isConnected);
        verify(mockRemoteDataSource.watchNotifications('user789'));
      });

      test('should return NetworkFailure when not connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = repository.watchNotifications('user789');

        // Assert
        final emittedValue = await result.first;
        expect(emittedValue.isLeft(), true);
        emittedValue.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.failureMessage, 'No internet connection');
          },
          (notifications) => fail('Should not emit success'),
        );
        verify(mockNetworkInfo.isConnected);
        verifyNever(mockRemoteDataSource.watchNotifications(any));
      });

      test('should return ServerFailure when datasource throws exception', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.watchNotifications('user789'))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));

        // Act
        final result = repository.watchNotifications('user789');

        // Assert
        final emittedValue = await result.first;
        expect(emittedValue.isLeft(), true);
        emittedValue.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.failureMessage, contains('Firestore error'));
          },
          (notifications) => fail('Should not emit success'),
        );
      });
    });

    group('markAsRead', () {
      test('should update notification to read when connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.markAsRead('notif123'))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.markAsRead('notif123');

        // Assert
        expect(result, const Right(null));
        verify(mockNetworkInfo.isConnected);
        verify(mockRemoteDataSource.markAsRead('notif123'));
      });

      test('should return NetworkFailure when not connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.markAsRead('notif123');

        // Assert
        expect(
          result,
          const Left(NetworkFailure(failureMessage: 'No internet connection')),
        );
        verify(mockNetworkInfo.isConnected);
        verifyNever(mockRemoteDataSource.markAsRead(any));
      });

      test('should return ServerFailure when datasource throws exception', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.markAsRead('notif123'))
            .thenThrow(Exception('Update failed'));

        // Act
        final result = await repository.markAsRead('notif123');

        // Assert
        expect(
          result,
          isA<Left<Failure, void>>()
              .having(
                (left) => left.value,
                'failure',
                isA<ServerFailure>()
                    .having(
                      (failure) => failure.failureMessage,
                      'failureMessage',
                      contains('Exception: Update failed'),
                    ),
              ),
        );
      });
    });

    group('markAllAsRead', () {
      test('should mark all notifications as read when connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.markAllAsRead('user789'))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.markAllAsRead('user789');

        // Assert
        expect(result, const Right(null));
        verify(mockNetworkInfo.isConnected);
        verify(mockRemoteDataSource.markAllAsRead('user789'));
      });

      test('should return NetworkFailure when not connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.markAllAsRead('user789');

        // Assert
        expect(
          result,
          const Left(NetworkFailure(failureMessage: 'No internet connection')),
        );
        verify(mockNetworkInfo.isConnected);
        verifyNever(mockRemoteDataSource.markAllAsRead(any));
      });

      test('should return ServerFailure when datasource throws exception', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.markAllAsRead('user789'))
            .thenThrow(Exception('Batch update failed'));

        // Act
        final result = await repository.markAllAsRead('user789');

        // Assert
        expect(
          result,
          isA<Left<Failure, void>>()
              .having(
                (left) => left.value,
                'failure',
                isA<ServerFailure>(),
              ),
        );
      });
    });

    group('deleteNotification', () {
      test('should delete notification when connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.deleteNotification('notif123'))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.deleteNotification('notif123');

        // Assert
        expect(result, const Right(null));
        verify(mockNetworkInfo.isConnected);
        verify(mockRemoteDataSource.deleteNotification('notif123'));
      });

      test('should return NetworkFailure when not connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.deleteNotification('notif123');

        // Assert
        expect(
          result,
          const Left(NetworkFailure(failureMessage: 'No internet connection')),
        );
        verify(mockNetworkInfo.isConnected);
        verifyNever(mockRemoteDataSource.deleteNotification(any));
      });

      test('should return ServerFailure when datasource throws exception', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.deleteNotification('notif123'))
            .thenThrow(Exception('Delete failed'));

        // Act
        final result = await repository.deleteNotification('notif123');

        // Assert
        expect(
          result,
          isA<Left<Failure, void>>()
              .having(
                (left) => left.value,
                'failure',
                isA<ServerFailure>(),
              ),
        );
      });
    });

    group('clearAll', () {
      test('should clear all notifications when connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.clearAll('user789'))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.clearAll('user789');

        // Assert
        expect(result, const Right(null));
        verify(mockNetworkInfo.isConnected);
        verify(mockRemoteDataSource.clearAll('user789'));
      });

      test('should return NetworkFailure when not connected', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.clearAll('user789');

        // Assert
        expect(
          result,
          const Left(NetworkFailure(failureMessage: 'No internet connection')),
        );
        verify(mockNetworkInfo.isConnected);
        verifyNever(mockRemoteDataSource.clearAll(any));
      });

      test('should return ServerFailure when datasource throws exception', () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockRemoteDataSource.clearAll('user789'))
            .thenThrow(Exception('Batch delete failed'));

        // Act
        final result = await repository.clearAll('user789');

        // Assert
        expect(
          result,
          isA<Left<Failure, void>>()
              .having(
                (left) => left.value,
                'failure',
                isA<ServerFailure>(),
              ),
        );
      });
    });
  });
}
