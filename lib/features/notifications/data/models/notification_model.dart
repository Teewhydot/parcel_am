import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/enums/notification_type.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.data,
    required super.timestamp,
    required super.isRead,
    super.chatId,
    super.senderId,
    super.senderName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isRead: json['isRead'] as bool? ?? false,
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
    );
  }

  factory NotificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return NotificationModel.fromJson({...data, 'id': doc.id});
  }

  factory NotificationModel.fromRemoteMessage(
    RemoteMessage message,
    String userId,
  ) {
    final notification = message.notification;
    final data = message.data;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: NotificationTypeExtension.fromString(
        data['type'] as String? ?? 'chat_message',
      ),
      title: notification?.title ?? data['title'] as String? ?? '',
      body: notification?.body ?? data['body'] as String? ?? '',
      data: Map<String, dynamic>.from(data),
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
      chatId: data['chatId'] as String?,
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
    };
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      title: entity.title,
      body: entity.body,
      data: entity.data,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      chatId: entity.chatId,
      senderId: entity.senderId,
      senderName: entity.senderName,
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      timestamp: timestamp,
      isRead: isRead,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
    );
  }
}
