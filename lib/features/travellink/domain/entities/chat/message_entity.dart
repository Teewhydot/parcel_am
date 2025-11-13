import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  file,
  system,
}

class MessageEntity extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String? replyToId;
  final Map<String, dynamic> metadata;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.replyToId,
    this.metadata = const {},
  });

  MessageEntity copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        content,
        type,
        timestamp,
        isRead,
        readBy,
        replyToId,
        metadata,
      ];
}
