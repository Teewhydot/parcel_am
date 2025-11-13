import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic> metadata;
  final String? replyToMessageId;
  final bool isDeleted;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.metadata = const {},
    this.replyToMessageId,
    this.isDeleted = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      content: data['content'] as String? ?? '',
      type: _typeFromString(data['type'] as String? ?? 'text'),
      status: _statusFromString(data['status'] as String? ?? 'sent'),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      fileUrl: data['fileUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      replyToMessageId: data['replyToMessageId'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      content: entity.content,
      type: entity.type,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      thumbnailUrl: entity.thumbnailUrl,
      metadata: entity.metadata,
      replyToMessageId: entity.replyToMessageId,
      isDeleted: entity.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': _typeToString(type),
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'isDeleted': isDeleted,
    };
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl,
      metadata: metadata,
      replyToMessageId: replyToMessageId,
      isDeleted: isDeleted,
    );
  }

  static MessageType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  static String _typeToString(MessageType type) {
    return type.name;
  }

  static MessageStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  static String _statusToString(MessageStatus status) {
    return status.name;
  }
}
