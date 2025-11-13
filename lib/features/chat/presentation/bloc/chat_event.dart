import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadRequested extends ChatEvent {
  final String userId;

  const ChatLoadRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class ChatDeleteRequested extends ChatEvent {
  final String chatId;

  const ChatDeleteRequested(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatMarkAsReadRequested extends ChatEvent {
  final String chatId;

  const ChatMarkAsReadRequested(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class ChatTogglePinRequested extends ChatEvent {
  final String chatId;
  final bool isPinned;

  const ChatTogglePinRequested(this.chatId, this.isPinned);

  @override
  List<Object> get props => [chatId, isPinned];
}

class ChatToggleMuteRequested extends ChatEvent {
  final String chatId;
  final bool isMuted;

  const ChatToggleMuteRequested(this.chatId, this.isMuted);

  @override
  List<Object> get props => [chatId, isMuted];
}

class ChatSearchUsersRequested extends ChatEvent {
  final String query;

  const ChatSearchUsersRequested(this.query);

  @override
  List<Object> get props => [query];
}

class ChatCreateRequested extends ChatEvent {
  final String currentUserId;
  final String participantId;

  const ChatCreateRequested(this.currentUserId, this.participantId);

  @override
  List<Object> get props => [currentUserId, participantId];
}

class ChatFilterChanged extends ChatEvent {
  final String filter;

  const ChatFilterChanged(this.filter);

  @override
  List<Object> get props => [filter];
}
