import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/chat_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadRequested extends ChatEvent {
  final String userId;

  const ChatLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ChatCreateRequested extends ChatEvent {
  final List<String> participantIds;

  const ChatCreateRequested(this.participantIds);

  @override
  List<Object?> get props => [participantIds];
}

class ChatUpdated extends ChatEvent {
  final List<ChatEntity> chats;

  const ChatUpdated(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChatMarkAsRead extends ChatEvent {
  final String chatId;
  final String userId;

  const ChatMarkAsRead(this.chatId, this.userId);

  @override
  List<Object?> get props => [chatId, userId];
}

class ChatStreamError extends ChatEvent {
  final String error;

  const ChatStreamError(this.error);

  @override
  List<Object?> get props => [error];
}
