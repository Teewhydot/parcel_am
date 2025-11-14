import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/message_type.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatId;

  const LoadMessages(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class LoadChat extends ChatEvent {
  final String chatId;

  const LoadChat(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class SendMessage extends ChatEvent {
  final Message message;

  const SendMessage(this.message);

  @override
  List<Object> get props => [message];
}

class SendMediaMessage extends ChatEvent {
  final String filePath;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final MessageType type;
  final String? replyToMessageId;

  const SendMediaMessage({
    required this.filePath,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    this.replyToMessageId,
  });

  @override
  List<Object?> get props => [
        filePath,
        chatId,
        senderId,
        senderName,
        senderAvatar,
        type,
        replyToMessageId,
      ];
}

class MarkMessageAsRead extends ChatEvent {
  final String chatId;
  final String messageId;
  final String userId;

  const MarkMessageAsRead({
    required this.chatId,
    required this.messageId,
    required this.userId,
  });

  @override
  List<Object> get props => [chatId, messageId, userId];
}

class SetTypingStatus extends ChatEvent {
  final String chatId;
  final String userId;
  final bool isTyping;

  const SetTypingStatus({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatId, userId, isTyping];
}

class UpdateLastSeen extends ChatEvent {
  final String chatId;
  final String userId;

  const UpdateLastSeen({
    required this.chatId,
    required this.userId,
  });

  @override
  List<Object> get props => [chatId, userId];
}

class SetReplyToMessage extends ChatEvent {
  final Message? message;

  const SetReplyToMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class DeleteMessage extends ChatEvent {
  final String messageId;

  const DeleteMessage(this.messageId);

  @override
  List<Object> get props => [messageId];
}

class ChatLoadRequested extends ChatEvent {
  final String userId;

  const ChatLoadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class ChatFilterChanged extends ChatEvent {
  final String filter;

  const ChatFilterChanged(this.filter);

  @override
  List<Object> get props => [filter];
}

class ChatTogglePinRequested extends ChatEvent {
  final String chatId;

  const ChatTogglePinRequested(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatToggleMuteRequested extends ChatEvent {
  final String chatId;

  const ChatToggleMuteRequested(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatMarkAsReadRequested extends ChatEvent {
  final String chatId;

  const ChatMarkAsReadRequested(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatDeleteRequested extends ChatEvent {
  final String chatId;

  const ChatDeleteRequested(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatCreateRequested extends ChatEvent {
  final List<String> participantIds;

  const ChatCreateRequested(this.participantIds);

  @override
  List<Object> get props => [participantIds];
}

class ChatSearchUsersRequested extends ChatEvent {
  final String query;

  const ChatSearchUsersRequested(this.query);

  @override
  List<Object> get props => [query];
}
