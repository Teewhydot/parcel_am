import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/enums/notification_type.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/features/notifications/domain/entities/notification_entity.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_event.dart';
import 'package:parcel_am/features/notifications/presentation/bloc/notification_state.dart';
import 'package:parcel_am/features/notifications/presentation/screens/notifications_screen.dart';

import 'notifications_screen_test.mocks.dart';

@GenerateMocks([NotificationBloc])
void main() {
  late MockNotificationBloc mockNotificationBloc;

  setUp(() {
    mockNotificationBloc = MockNotificationBloc();
    // Enable test mode for GetX
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Widget createWidgetUnderTest() {
    return GetMaterialApp(
      home: BlocProvider<NotificationBloc>.value(
        value: mockNotificationBloc,
        child: const NotificationsScreen(userId: 'test-user-id'),
      ),
      getPages: [
        GetPage(
          name: Routes.chat,
          page: () => const Scaffold(body: Text('Chat Screen')),
        ),
      ],
    );
  }

  final testNotifications = [
    NotificationEntity(
      id: '1',
      userId: 'test-user-id',
      type: NotificationType.chatMessage,
      title: 'New Message',
      body: 'John sent you a message',
      data: {'chatId': 'chat-1'},
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      chatId: 'chat-1',
      senderId: 'john-id',
      senderName: 'John Doe',
    ),
    NotificationEntity(
      id: '2',
      userId: 'test-user-id',
      type: NotificationType.systemAlert,
      title: 'System Alert',
      body: 'Your KYC was approved',
      data: {},
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  group('NotificationsScreen', () {
    testWidgets('renders correctly with notifications', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => Stream.value(
          NotificationsLoaded(
            notifications: testNotifications,
            unreadCount: 1,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('New Message'), findsOneWidget);
      expect(find.text('System Alert'), findsOneWidget);
      verify(mockNotificationBloc.add(any)).called(1);
    });

    testWidgets('notification tap navigates to chat screen', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => Stream.value(
          NotificationsLoaded(
            notifications: testNotifications,
            unreadCount: 1,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap the first notification
      final notificationCard = find.text('New Message');
      expect(notificationCard, findsOneWidget);
      await tester.tap(notificationCard);
      await tester.pumpAndSettle();

      // Assert - Verify MarkAsRead event was dispatched
      verify(mockNotificationBloc.add(argThat(
        isA<MarkAsRead>().having((e) => e.notificationId, 'notificationId', '1'),
      ))).called(1);

      // Verify navigation to chat screen occurred
      expect(find.text('Chat Screen'), findsOneWidget);
    });

    testWidgets('swipe-to-delete removes notification', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => Stream.value(
          NotificationsLoaded(
            notifications: testNotifications,
            unreadCount: 1,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Swipe the notification to reveal delete action
      await tester.drag(find.text('New Message'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      // Assert - Check that slidable actions are visible
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('pull-to-refresh reloads notifications', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => Stream.value(
          NotificationsLoaded(
            notifications: testNotifications,
            unreadCount: 1,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Perform pull-to-refresh
      await tester.drag(find.text('New Message'), const Offset(0.0, 300.0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Verify LoadNotifications event was dispatched
      verify(mockNotificationBloc.add(argThat(
        isA<LoadNotifications>().having((e) => e.userId, 'userId', 'test-user-id'),
      ))).called(greaterThan(1)); // Called on init and on refresh
    });

    testWidgets('empty state displays when no notifications', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
        ),
      );
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => Stream.value(
          const NotificationsLoaded(
            notifications: [],
            unreadCount: 0,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    testWidgets('loading state displays CircularProgressIndicator', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(NotificationsLoading());
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state displays error message with retry button', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load notifications';
      when(mockNotificationBloc.state).thenReturn(const NotificationError(errorMessage));
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert - Error message appears in both SnackBar and error state UI
      expect(find.text(errorMessage), findsWidgets);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Verify LoadNotifications event was dispatched
      verify(mockNotificationBloc.add(argThat(
        isA<LoadNotifications>().having((e) => e.userId, 'userId', 'test-user-id'),
      ))).called(greaterThan(1)); // Called on init and on retry
    });

    testWidgets('mark all as read button dispatches MarkAllAsRead event', (WidgetTester tester) async {
      // Arrange
      when(mockNotificationBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );
      when(mockNotificationBloc.stream).thenAnswer(
        (_) => Stream.value(
          NotificationsLoaded(
            notifications: testNotifications,
            unreadCount: 1,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap mark all as read button
      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      // Assert - Verify MarkAllAsRead event was dispatched
      verify(mockNotificationBloc.add(argThat(
        isA<MarkAllAsRead>().having((e) => e.userId, 'userId', 'test-user-id'),
      ))).called(1);
    });
  });
}
