import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/core/enums/notification_type.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';
import 'package:parcel_am/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('NotificationModel', () {
    final testTimestamp = DateTime(2025, 11, 14, 10, 30);
    final testData = {
      'chatId': 'chat123',
      'senderId': 'user456',
      'messagePreview': 'Hello there!',
    };

    final testNotificationModel = NotificationModel(
      id: 'notif123',
      userId: 'user789',
      type: NotificationType.chatMessage,
      title: 'New Message',
      body: 'John Doe sent you a message',
      data: testData,
      timestamp: testTimestamp,
      isRead: false,
      chatId: 'chat123',
      senderId: 'user456',
      senderName: 'John Doe',
    );

    group('fromJson', () {
      test('should deserialize JSON with all fields correctly', () {
        // Arrange
        final json = {
          'id': 'notif123',
          'userId': 'user789',
          'type': 'chat_message',
          'title': 'New Message',
          'body': 'John Doe sent you a message',
          'data': testData,
          'timestamp': Timestamp.fromDate(testTimestamp),
          'isRead': false,
          'chatId': 'chat123',
          'senderId': 'user456',
          'senderName': 'John Doe',
        };

        // Act
        final result = NotificationModel.fromJson(json);

        // Assert
        expect(result.id, 'notif123');
        expect(result.userId, 'user789');
        expect(result.type, NotificationType.chatMessage);
        expect(result.title, 'New Message');
        expect(result.body, 'John Doe sent you a message');
        expect(result.data, testData);
        expect(result.timestamp, testTimestamp);
        expect(result.isRead, false);
        expect(result.chatId, 'chat123');
        expect(result.senderId, 'user456');
        expect(result.senderName, 'John Doe');
      });

      test('should handle missing optional fields with defaults', () {
        // Arrange
        final json = {
          'id': 'notif123',
          'userId': 'user789',
          'type': 'system_alert',
          'title': 'System Alert',
          'body': 'System update available',
          'timestamp': Timestamp.fromDate(testTimestamp),
        };

        // Act
        final result = NotificationModel.fromJson(json);

        // Assert
        expect(result.id, 'notif123');
        expect(result.userId, 'user789');
        expect(result.type, NotificationType.systemAlert);
        expect(result.title, 'System Alert');
        expect(result.body, 'System update available');
        expect(result.data, {});
        expect(result.isRead, false);
        expect(result.chatId, null);
        expect(result.senderId, null);
        expect(result.senderName, null);
      });

      test('should handle different notification types', () {
        // Test announcement type
        final announcementJson = {
          'id': 'notif456',
          'userId': 'user789',
          'type': 'announcement',
          'title': 'Announcement',
          'body': 'New feature available',
          'data': {},
          'timestamp': Timestamp.fromDate(testTimestamp),
          'isRead': true,
        };

        final announcement = NotificationModel.fromJson(announcementJson);
        expect(announcement.type, NotificationType.announcement);

        // Test reminder type
        final reminderJson = {
          'id': 'notif789',
          'userId': 'user789',
          'type': 'reminder',
          'title': 'Reminder',
          'body': 'Meeting in 10 minutes',
          'data': {},
          'timestamp': Timestamp.fromDate(testTimestamp),
          'isRead': false,
        };

        final reminder = NotificationModel.fromJson(reminderJson);
        expect(reminder.type, NotificationType.reminder);
      });
    });

    group('toJson', () {
      test('should serialize to JSON with all fields correctly', () {
        // Act
        final result = testNotificationModel.toJson();

        // Assert
        expect(result['id'], 'notif123');
        expect(result['userId'], 'user789');
        expect(result['type'], 'chat_message');
        expect(result['title'], 'New Message');
        expect(result['body'], 'John Doe sent you a message');
        expect(result['data'], testData);
        expect(result['timestamp'], Timestamp.fromDate(testTimestamp));
        expect(result['isRead'], false);
        expect(result['chatId'], 'chat123');
        expect(result['senderId'], 'user456');
        expect(result['senderName'], 'John Doe');
      });

      test('should handle null optional fields in serialization', () {
        // Arrange
        final model = NotificationModel(
          id: 'notif123',
          userId: 'user789',
          type: NotificationType.systemAlert,
          title: 'System Alert',
          body: 'Update available',
          data: {},
          timestamp: testTimestamp,
          isRead: true,
        );

        // Act
        final result = model.toJson();

        // Assert
        expect(result['chatId'], null);
        expect(result['senderId'], null);
        expect(result['senderName'], null);
      });
    });

    group('fromRemoteMessage', () {
      test('should convert FCM RemoteMessage to NotificationModel', () {
        // Arrange
        final remoteMessage = RemoteMessage(
          messageId: 'msg123',
          sentTime: testTimestamp,
          notification: const RemoteNotification(
            title: 'New Message',
            body: 'You have a new chat message',
          ),
          data: {
            'type': 'chat_message',
            'chatId': 'chat123',
            'senderId': 'user456',
            'senderName': 'John Doe',
            'title': 'Data Title',
            'body': 'Data Body',
          },
        );

        // Act
        final result = NotificationModel.fromRemoteMessage(
          remoteMessage,
          'user789',
        );

        // Assert
        expect(result.id, 'msg123');
        expect(result.userId, 'user789');
        expect(result.type, NotificationType.chatMessage);
        expect(result.title, 'New Message'); // From notification
        expect(result.body, 'You have a new chat message'); // From notification
        expect(result.timestamp, testTimestamp);
        expect(result.isRead, false);
        expect(result.chatId, 'chat123');
        expect(result.senderId, 'user456');
        expect(result.senderName, 'John Doe');
      });

      test('should handle RemoteMessage with data-only payload', () {
        // Arrange
        final remoteMessage = RemoteMessage(
          messageId: 'msg456',
          sentTime: testTimestamp,
          data: {
            'type': 'system_alert',
            'title': 'System Update',
            'body': 'New version available',
          },
        );

        // Act
        final result = NotificationModel.fromRemoteMessage(
          remoteMessage,
          'user789',
        );

        // Assert
        expect(result.id, 'msg456');
        expect(result.userId, 'user789');
        expect(result.type, NotificationType.systemAlert);
        expect(result.title, 'System Update'); // From data
        expect(result.body, 'New version available'); // From data
        expect(result.isRead, false);
      });

      test('should generate ID when messageId is null', () {
        // Arrange
        final remoteMessage = RemoteMessage(
          sentTime: testTimestamp,
          data: {
            'type': 'chat_message',
            'title': 'Test',
            'body': 'Test message',
          },
        );

        // Act
        final result = NotificationModel.fromRemoteMessage(
          remoteMessage,
          'user789',
        );

        // Assert
        expect(result.id, isNotEmpty);
        expect(result.timestamp, testTimestamp);
      });

      test('should use current time when sentTime is null', () {
        // Arrange
        final beforeTime = DateTime.now();
        final remoteMessage = RemoteMessage(
          messageId: 'msg789',
          data: {
            'type': 'chat_message',
            'title': 'Test',
            'body': 'Test message',
          },
        );

        // Act
        final result = NotificationModel.fromRemoteMessage(
          remoteMessage,
          'user789',
        );
        final afterTime = DateTime.now();

        // Assert
        expect(result.timestamp.isAfter(beforeTime) ||
               result.timestamp.isAtSameMomentAs(beforeTime), true);
        expect(result.timestamp.isBefore(afterTime) ||
               result.timestamp.isAtSameMomentAs(afterTime), true);
      });
    });

    group('entity conversion', () {
      test('should convert NotificationEntity to NotificationModel', () {
        // Arrange
        final entity = NotificationEntity(
          id: 'notif123',
          userId: 'user789',
          type: NotificationType.chatMessage,
          title: 'New Message',
          body: 'Test message',
          data: testData,
          timestamp: testTimestamp,
          isRead: false,
          chatId: 'chat123',
          senderId: 'user456',
          senderName: 'John Doe',
        );

        // Act
        final result = NotificationModel.fromEntity(entity);

        // Assert
        expect(result.id, entity.id);
        expect(result.userId, entity.userId);
        expect(result.type, entity.type);
        expect(result.title, entity.title);
        expect(result.body, entity.body);
        expect(result.data, entity.data);
        expect(result.timestamp, entity.timestamp);
        expect(result.isRead, entity.isRead);
        expect(result.chatId, entity.chatId);
        expect(result.senderId, entity.senderId);
        expect(result.senderName, entity.senderName);
      });

      test('should convert NotificationModel to NotificationEntity', () {
        // Act
        final result = testNotificationModel.toEntity();

        // Assert
        expect(result, isA<NotificationEntity>());
        expect(result.id, testNotificationModel.id);
        expect(result.userId, testNotificationModel.userId);
        expect(result.type, testNotificationModel.type);
        expect(result.title, testNotificationModel.title);
        expect(result.body, testNotificationModel.body);
        expect(result.data, testNotificationModel.data);
        expect(result.timestamp, testNotificationModel.timestamp);
        expect(result.isRead, testNotificationModel.isRead);
        expect(result.chatId, testNotificationModel.chatId);
        expect(result.senderId, testNotificationModel.senderId);
        expect(result.senderName, testNotificationModel.senderName);
      });
    });

    group('field validation', () {
      test('should preserve all required fields through serialization cycle', () {
        // Arrange
        final json = testNotificationModel.toJson();

        // Act
        final result = NotificationModel.fromJson(json);

        // Assert
        expect(result.id, testNotificationModel.id);
        expect(result.userId, testNotificationModel.userId);
        expect(result.type, testNotificationModel.type);
        expect(result.title, testNotificationModel.title);
        expect(result.body, testNotificationModel.body);
        expect(result.data, testNotificationModel.data);
        expect(result.timestamp, testNotificationModel.timestamp);
        expect(result.isRead, testNotificationModel.isRead);
        expect(result.chatId, testNotificationModel.chatId);
        expect(result.senderId, testNotificationModel.senderId);
        expect(result.senderName, testNotificationModel.senderName);
      });

      test('should correctly handle isRead flag', () {
        // Test unread notification
        final unreadJson = {
          'id': 'notif1',
          'userId': 'user1',
          'type': 'chat_message',
          'title': 'Test',
          'body': 'Test',
          'data': {},
          'timestamp': Timestamp.fromDate(testTimestamp),
          'isRead': false,
        };

        final unread = NotificationModel.fromJson(unreadJson);
        expect(unread.isRead, false);

        // Test read notification
        final readJson = {
          'id': 'notif2',
          'userId': 'user1',
          'type': 'chat_message',
          'title': 'Test',
          'body': 'Test',
          'data': {},
          'timestamp': Timestamp.fromDate(testTimestamp),
          'isRead': true,
        };

        final read = NotificationModel.fromJson(readJson);
        expect(read.isRead, true);
      });
    });
  });
}
