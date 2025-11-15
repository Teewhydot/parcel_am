import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/enums/notification_type.dart';
import 'package:parcel_am/core/errors/failures.dart';
import 'package:parcel_am/features/notifications/domain/entities/notification_entity.dart';
import 'package:parcel_am/features/notifications/domain/usecases/notification_usecase.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_event.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_state.dart';

import 'notification_bloc_test.mocks.dart';

@GenerateMocks([NotificationUseCase])
void main() {
  late NotificationBloc bloc;
  late MockNotificationUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockNotificationUseCase();
    bloc = NotificationBloc(notificationUseCase: mockUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  group('NotificationBloc', () {
    const userId = 'test-user-id';
    const notificationId = 'test-notification-id';

    final testNotifications = [
      NotificationEntity(
        id: '1',
        userId: userId,
        type: NotificationType.chatMessage,
        title: 'New Message',
        body: 'You have a new message',
        data: {'chatId': 'chat-1'},
        timestamp: DateTime.now(),
        isRead: false,
        chatId: 'chat-1',
        senderId: 'sender-1',
        senderName: 'John Doe',
      ),
      NotificationEntity(
        id: '2',
        userId: userId,
        type: NotificationType.systemAlert,
        title: 'System Alert',
        body: 'System maintenance scheduled',
        data: {},
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ];

    test('initial state is NotificationInitial', () {
      expect(bloc.state, equals(NotificationInitial()));
    });

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationsLoading, NotificationsLoaded] when LoadNotifications succeeds',
      build: () {
        when(mockUseCase.watchNotifications(userId)).thenAnswer(
          (_) => Stream.value(Right(testNotifications)),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications(userId)),
      expect: () => [
        NotificationsLoading(),
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      ],
      verify: (_) {
        verify(mockUseCase.watchNotifications(userId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationsLoading, NotificationError] when LoadNotifications fails',
      build: () {
        when(mockUseCase.watchNotifications(userId)).thenAnswer(
          (_) => Stream.value(const Left(ServerFailure(failureMessage: 'Failed to load notifications'))),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications(userId)),
      expect: () => [
        NotificationsLoading(),
        const NotificationError('Failed to load notifications'),
      ],
      verify: (_) {
        verify(mockUseCase.watchNotifications(userId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits updated state when MarkAsRead succeeds',
      build: () {
        when(mockUseCase.markAsRead(notificationId)).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const MarkAsRead(notificationId)),
      verify: (_) {
        verify(mockUseCase.markAsRead(notificationId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits error state when MarkAsRead fails',
      build: () {
        when(mockUseCase.markAsRead(notificationId)).thenAnswer(
          (_) async => const Left(ServerFailure(failureMessage: 'Failed to mark as read')),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const MarkAsRead(notificationId)),
      expect: () => [
        const NotificationError('Failed to mark as read'),
      ],
      verify: (_) {
        verify(mockUseCase.markAsRead(notificationId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits updated state when MarkAllAsRead succeeds',
      build: () {
        when(mockUseCase.markAllAsRead(userId)).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const MarkAllAsRead(userId)),
      verify: (_) {
        verify(mockUseCase.markAllAsRead(userId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits error state when MarkAllAsRead fails',
      build: () {
        when(mockUseCase.markAllAsRead(userId)).thenAnswer(
          (_) async => const Left(ServerFailure(failureMessage: 'Failed to mark all as read')),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const MarkAllAsRead(userId)),
      expect: () => [
        const NotificationError('Failed to mark all as read'),
      ],
      verify: (_) {
        verify(mockUseCase.markAllAsRead(userId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits updated state when DeleteNotification succeeds',
      build: () {
        when(mockUseCase.deleteNotification(notificationId)).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const DeleteNotification(notificationId)),
      verify: (_) {
        verify(mockUseCase.deleteNotification(notificationId)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationInitial] when ClearAll succeeds',
      build: () {
        when(mockUseCase.clearAll(userId)).thenAnswer(
          (_) async => const Right(null),
        );
        return bloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(const ClearAll(userId)),
      expect: () => [
        NotificationInitial(),
      ],
      verify: (_) {
        verify(mockUseCase.clearAll(userId)).called(1);
      },
    );
  });
}
