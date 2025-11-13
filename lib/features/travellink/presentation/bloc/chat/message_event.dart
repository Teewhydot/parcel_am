import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/message_entity.dart';

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

class MessageLoadRequested extends MessageEvent {
  final String chatId;

  const MessageLoadRequested(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class MessageSendRequested extends MessageEvent {
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? replyToId;

  const MessageSendRequested({
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.replyToId,
  });

  @override
  List<Object?> get props => [chatId, senderId, content, type, replyToId];
}

class MessageDeleteRequested extends MessageEvent {
  final String messageId;

  const MessageDeleteRequested(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class MessagesUpdated extends MessageEvent {
  final String chatId;
  final List<MessageEntity> messages;

  const MessagesUpdated(this.chatId, this.messages);

  @override
  List<Object?> get props => [chatId, messages];
}

class MessageStreamError extends MessageEvent {
  final String chatId;
  final String error;

  const MessageStreamError(this.chatId, this.error);

  @override
  List<Object?> get props => [chatId, error];
}

class MessageUnsubscribeRequested extends MessageEvent {
  final String chatId;

  const MessageUnsubscribeRequested(this.chatId);

  @override
  List<Object?> get props => [chatId];
}
