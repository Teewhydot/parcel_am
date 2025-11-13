import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/presence_entity.dart';

abstract class PresenceEvent extends Equatable {
  const PresenceEvent();

  @override
  List<Object?> get props => [];
}

class PresenceLoadRequested extends PresenceEvent {
  final String userId;

  const PresenceLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PresenceUpdateRequested extends PresenceEvent {
  final String userId;
  final OnlineStatus status;
  final String? currentChatId;

  const PresenceUpdateRequested({
    required this.userId,
    required this.status,
    this.currentChatId,
  });

  @override
  List<Object?> get props => [userId, status, currentChatId];
}

class TypingStarted extends PresenceEvent {
  final String userId;
  final String chatId;

  const TypingStarted({
    required this.userId,
    required this.chatId,
  });

  @override
  List<Object?> get props => [userId, chatId];
}

class TypingEnded extends PresenceEvent {
  final String userId;
  final String chatId;

  const TypingEnded({
    required this.userId,
    required this.chatId,
  });

  @override
  List<Object?> get props => [userId, chatId];
}

class PresenceUpdated extends PresenceEvent {
  final String userId;
  final PresenceEntity presence;

  const PresenceUpdated(this.userId, this.presence);

  @override
  List<Object?> get props => [userId, presence];
}

class TypingStatusUpdated extends PresenceEvent {
  final String chatId;
  final Map<String, bool> typingUsers;

  const TypingStatusUpdated(this.chatId, this.typingUsers);

  @override
  List<Object?> get props => [chatId, typingUsers];
}

class PresenceStreamError extends PresenceEvent {
  final String userId;
  final String error;

  const PresenceStreamError(this.userId, this.error);

  @override
  List<Object?> get props => [userId, error];
}

class PresenceUnsubscribeRequested extends PresenceEvent {
  final String userId;

  const PresenceUnsubscribeRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TypingUnsubscribeRequested extends PresenceEvent {
  final String chatId;

  const TypingUnsubscribeRequested(this.chatId);

  @override
  List<Object?> get props => [chatId];
}
