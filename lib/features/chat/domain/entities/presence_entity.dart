import 'package:equatable/equatable.dart';

class PresenceEntity extends Equatable {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;
  final String? typingInChatId;

  const PresenceEntity({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    required this.isTyping,
    this.typingInChatId,
  });

  PresenceEntity copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
    String? typingInChatId,
  }) {
    return PresenceEntity(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      typingInChatId: typingInChatId ?? this.typingInChatId,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        isOnline,
        lastSeen,
        isTyping,
        typingInChatId,
      ];
}
