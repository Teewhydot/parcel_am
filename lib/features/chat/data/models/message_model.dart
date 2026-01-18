import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.senderName,
    super.senderAvatar,
    required super.content,
    required super.type,
    required super.status,
    required super.timestamp,
    super.mediaUrl,
    super.thumbnailUrl,
    super.fileName,
    super.fileSize,
    super.replyToMessageId,
    super.replyToMessage,
    super.isDeleted,
    super.readBy,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      mediaUrl: json['mediaUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      replyToMessageId: json['replyToMessageId'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      readBy: json['readBy'] != null
          ? Map.fromEntries(
              (json['readBy'] as Map<String, dynamic>)
                  .entries
                  .where((e) => e.value != null && e.value is Timestamp)
                  .map((e) => MapEntry(e.key, (e.value as Timestamp).toDate())),
            )
          : null,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return MessageModel.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'replyToMessageId': replyToMessageId,
      'isDeleted': isDeleted,
      'readBy': readBy?.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      chatId: message.chatId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderAvatar: message.senderAvatar,
      content: message.content,
      type: message.type,
      status: message.status,
      timestamp: message.timestamp,
      mediaUrl: message.mediaUrl,
      thumbnailUrl: message.thumbnailUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      replyToMessageId: message.replyToMessageId,
      replyToMessage: message.replyToMessage,
      isDeleted: message.isDeleted,
      readBy: message.readBy,
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      timestamp: timestamp,
      isRead: status == MessageStatus.read,
      replyToMessageId: replyToMessageId,
      metadata: {
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'isDeleted': isDeleted,
      },
    );
  }
}
