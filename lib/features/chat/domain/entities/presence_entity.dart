import 'package:equatable/equatable.dart';

enum PresenceStatus { online, offline, typing, away }

class PresenceEntity extends Equatable {
  final String userId;
  final PresenceStatus status;
  final DateTime? lastSeen;
  final bool isTyping;
  final String? typingInChatId;
  final DateTime? lastTypingAt;

  const PresenceEntity({
    required this.userId,
    required this.status,
    this.lastSeen,
    required this.isTyping,
    this.typingInChatId,
    this.lastTypingAt,
  });

  bool get isOnline => status == PresenceStatus.online;

  PresenceEntity copyWith({
    String? userId,
    PresenceStatus? status,
    DateTime? lastSeen,
    bool? isTyping,
    String? typingInChatId,
    DateTime? lastTypingAt,
  }) {
    return PresenceEntity(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      typingInChatId: typingInChatId ?? this.typingInChatId,
      lastTypingAt: lastTypingAt ?? this.lastTypingAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        status,
        lastSeen,
        isTyping,
        typingInChatId,
        lastTypingAt,
      ];
}
