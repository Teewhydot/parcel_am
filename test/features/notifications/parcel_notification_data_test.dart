import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/notifications/domain/enums/notification_type.dart';
import 'package:parcel_am/features/notifications/data/models/notification_model.dart';
import 'package:parcel_am/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('NotificationType Enum - Parcel Request Accepted', () {
    test('should map parcelRequestAccepted to parcel_request_accepted string',
        () {
      // Arrange
      const type = NotificationType.parcelRequestAccepted;

      // Act
      final value = type.value;

      // Assert
      expect(value, 'parcel_request_accepted');
    });

    test('should parse parcel_request_accepted string to parcelRequestAccepted',
        () {
      // Arrange
      const typeString = 'parcel_request_accepted';

      // Act
      final type = NotificationTypeExtension.fromString(typeString);

      // Assert
      expect(type, NotificationType.parcelRequestAccepted);
    });
  });

  group('NotificationEntity - Parcel Fields', () {
    test('should create NotificationEntity with parcelId field', () {
      // Arrange & Act
      final entity = NotificationEntity(
        id: 'test-id',
        userId: 'user-123',
        type: NotificationType.parcelRequestAccepted,
        title: 'Request Accepted!',
        body: 'John accepted your parcel request',
        data: {},
        timestamp: DateTime.now(),
        isRead: false,
        parcelId: 'parcel-456',
        travelerId: 'traveler-789',
        travelerName: 'John Doe',
      );

      // Assert
      expect(entity.parcelId, 'parcel-456');
      expect(entity.travelerId, 'traveler-789');
      expect(entity.travelerName, 'John Doe');
    });

    test('should support null parcelId for backward compatibility', () {
      // Arrange & Act
      final entity = NotificationEntity(
        id: 'test-id',
        userId: 'user-123',
        type: NotificationType.chatMessage,
        title: 'New Message',
        body: 'You have a new message',
        data: {},
        timestamp: DateTime.now(),
        isRead: false,
        chatId: 'chat-123',
      );

      // Assert
      expect(entity.parcelId, isNull);
      expect(entity.travelerId, isNull);
      expect(entity.travelerName, isNull);
      expect(entity.chatId, 'chat-123');
    });

    test('should include parcel fields in equality comparison', () {
      // Arrange
      final timestamp = DateTime.now();
      final entity1 = NotificationEntity(
        id: 'test-id',
        userId: 'user-123',
        type: NotificationType.parcelRequestAccepted,
        title: 'Request Accepted!',
        body: 'Test body',
        data: {},
        timestamp: timestamp,
        isRead: false,
        parcelId: 'parcel-456',
      );

      final entity2 = NotificationEntity(
        id: 'test-id',
        userId: 'user-123',
        type: NotificationType.parcelRequestAccepted,
        title: 'Request Accepted!',
        body: 'Test body',
        data: {},
        timestamp: timestamp,
        isRead: false,
        parcelId: 'parcel-456',
      );

      final entity3 = NotificationEntity(
        id: 'test-id',
        userId: 'user-123',
        type: NotificationType.parcelRequestAccepted,
        title: 'Request Accepted!',
        body: 'Test body',
        data: {},
        timestamp: timestamp,
        isRead: false,
        parcelId: 'parcel-different',
      );

      // Assert
      expect(entity1, equals(entity2));
      expect(entity1, isNot(equals(entity3)));
    });
  });

  group('NotificationModel - Parcel Serialization', () {
    test('should serialize parcelId to JSON', () {
      // Arrange
      final model = NotificationModel(
        id: 'test-id',
        userId: 'user-123',
        type: NotificationType.parcelRequestAccepted,
        title: 'Request Accepted!',
        body: 'Test body',
        data: {},
        timestamp: DateTime.now(),
        isRead: false,
        parcelId: 'parcel-456',
        travelerId: 'traveler-789',
        travelerName: 'John Doe',
      );

      // Act
      final json = model.toJson();

      // Assert
      expect(json['parcelId'], 'parcel-456');
      expect(json['travelerId'], 'traveler-789');
      expect(json['travelerName'], 'John Doe');
      expect(json['type'], 'parcel_request_accepted');
    });

    test('should deserialize parcelId from JSON', () {
      // Arrange
      final json = {
        'id': 'test-id',
        'userId': 'user-123',
        'type': 'parcel_request_accepted',
        'title': 'Request Accepted!',
        'body': 'Test body',
        'data': {},
        'timestamp': Timestamp.now(),
        'isRead': false,
        'parcelId': 'parcel-456',
        'travelerId': 'traveler-789',
        'travelerName': 'John Doe',
      };

      // Act
      final model = NotificationModel.fromJson(json);

      // Assert
      expect(model.parcelId, 'parcel-456');
      expect(model.travelerId, 'traveler-789');
      expect(model.travelerName, 'John Doe');
      expect(model.type, NotificationType.parcelRequestAccepted);
    });

    test('should handle missing parcelId in JSON for backward compatibility',
        () {
      // Arrange
      final json = {
        'id': 'test-id',
        'userId': 'user-123',
        'type': 'chat_message',
        'title': 'New Message',
        'body': 'Test body',
        'data': {},
        'timestamp': Timestamp.now(),
        'isRead': false,
        'chatId': 'chat-123',
      };

      // Act
      final model = NotificationModel.fromJson(json);

      // Assert
      expect(model.parcelId, isNull);
      expect(model.travelerId, isNull);
      expect(model.travelerName, isNull);
      expect(model.chatId, 'chat-123');
    });

    test(
        'should extract parcel fields from RemoteMessage data payload for parcel notifications',
        () {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-123',
        data: {
          'type': 'parcel_request_accepted',
          'title': 'Request Accepted!',
          'body': 'John accepted your parcel request',
          'parcelId': 'parcel-456',
          'travelerId': 'traveler-789',
          'travelerName': 'John Doe',
        },
        notification: RemoteNotification(
          title: 'Request Accepted!',
          body: 'John accepted your parcel request',
        ),
      );

      // Act
      final model =
          NotificationModel.fromRemoteMessage(remoteMessage, 'user-123');

      // Assert
      expect(model.type, NotificationType.parcelRequestAccepted);
      expect(model.parcelId, 'parcel-456');
      expect(model.travelerId, 'traveler-789');
      expect(model.travelerName, 'John Doe');
      expect(model.userId, 'user-123');
    });

    test('should handle RemoteMessage without parcel fields gracefully', () {
      // Arrange
      final remoteMessage = RemoteMessage(
        messageId: 'msg-123',
        data: {
          'type': 'chat_message',
          'title': 'New Message',
          'body': 'You have a new message',
          'chatId': 'chat-123',
        },
        notification: RemoteNotification(
          title: 'New Message',
          body: 'You have a new message',
        ),
      );

      // Act
      final model =
          NotificationModel.fromRemoteMessage(remoteMessage, 'user-123');

      // Assert
      expect(model.type, NotificationType.chatMessage);
      expect(model.parcelId, isNull);
      expect(model.travelerId, isNull);
      expect(model.travelerName, isNull);
      expect(model.chatId, 'chat-123');
    });
  });
}
