import 'package:equatable/equatable.dart';
import '../enums/notification_type.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? chatId;
  final String? senderId;
  final String? senderName;
  final String? parcelId;
  final String? travelerId;
  final String? travelerName;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    required this.isRead,
    this.chatId,
    this.senderId,
    this.senderName,
    this.parcelId,
    this.travelerId,
    this.travelerName,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? chatId,
    String? senderId,
    String? senderName,
    String? parcelId,
    String? travelerId,
    String? travelerName,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      parcelId: parcelId ?? this.parcelId,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        data,
        timestamp,
        isRead,
        chatId,
        senderId,
        senderName,
        parcelId,
        travelerId,
        travelerName,
      ];
}
