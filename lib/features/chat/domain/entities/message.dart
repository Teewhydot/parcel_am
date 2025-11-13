import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, document }

enum MessageStatus { sending, sent, delivered, read, failed }

class Message extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final String? replyToMessageId;
  final Message? replyToMessage;
  final bool isDeleted;
  final Map<String, DateTime>? readBy;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.replyToMessageId,
    this.replyToMessage,
    this.isDeleted = false,
    this.readBy,
  });

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        senderAvatar,
        content,
        type,
        status,
        timestamp,
        mediaUrl,
        thumbnailUrl,
        fileName,
        fileSize,
        replyToMessageId,
        isDeleted,
        readBy,
      ];

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    String? replyToMessageId,
    Message? replyToMessage,
    bool? isDeleted,
    Map<String, DateTime>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
    );
  }
}
