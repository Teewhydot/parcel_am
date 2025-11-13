import 'package:equatable/equatable.dart';

enum OnlineStatus {
  online,
  offline,
  away,
}

class PresenceEntity extends Equatable {
  final String userId;
  final OnlineStatus status;
  final DateTime? lastSeen;
  final String? currentChatId;
  final bool isTyping;

  const PresenceEntity({
    required this.userId,
    required this.status,
    this.lastSeen,
    this.currentChatId,
    this.isTyping = false,
  });

  PresenceEntity copyWith({
    String? userId,
    OnlineStatus? status,
    DateTime? lastSeen,
    String? currentChatId,
    bool? isTyping,
  }) {
    return PresenceEntity(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      currentChatId: currentChatId ?? this.currentChatId,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        status,
        lastSeen,
        currentChatId,
        isTyping,
      ];
}
