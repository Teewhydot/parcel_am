import '../../domain/entities/presence_entity.dart';

class PresenceModel {
  final String userId;
  final PresenceStatus status;
  final DateTime? lastSeen;
  final bool isTyping;
  final String? typingInChatId;
  final DateTime? lastTypingAt;

  const PresenceModel({
    required this.userId,
    required this.status,
    this.lastSeen,
    this.isTyping = false,
    this.typingInChatId,
    this.lastTypingAt,
  });

  /// Create from RTDB snapshot data
  factory PresenceModel.fromRtdb(String id, Map<String, dynamic> data) {
    return PresenceModel(
      userId: id,
      status: _statusFromString(data['status'] as String? ?? 'offline'),
      lastSeen: data['lastSeen'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'] as int)
          : null,
      isTyping: data['isTyping'] as bool? ?? false,
      typingInChatId: data['typingInChatId'] as String?,
      lastTypingAt: data['lastTypingAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['lastTypingAt'] as int)
          : null,
    );
  }

  factory PresenceModel.fromEntity(PresenceEntity entity) {
    return PresenceModel(
      userId: entity.userId,
      status: entity.status,
      lastSeen: entity.lastSeen,
      isTyping: entity.isTyping,
      typingInChatId: entity.typingInChatId,
      lastTypingAt: entity.lastTypingAt,
    );
  }

  /// Convert to RTDB format (timestamps as milliseconds)
  Map<String, dynamic> toRtdb() {
    return {
      'status': _statusToString(status),
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isTyping': isTyping,
      'typingInChatId': typingInChatId,
      'lastTypingAt': lastTypingAt?.millisecondsSinceEpoch,
    };
  }

  /// Legacy JSON format (kept for compatibility)
  Map<String, dynamic> toJson() {
    return {
      'status': _statusToString(status),
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isTyping': isTyping,
      'typingInChatId': typingInChatId,
      'lastTypingAt': lastTypingAt?.millisecondsSinceEpoch,
    };
  }

  PresenceEntity toEntity() {
    return PresenceEntity(
      userId: userId,
      status: status,
      lastSeen: lastSeen,
      isTyping: isTyping,
      typingInChatId: typingInChatId,
      lastTypingAt: lastTypingAt,
    );
  }

  static PresenceStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return PresenceStatus.online;
      case 'offline':
        return PresenceStatus.offline;
      case 'away':
        return PresenceStatus.away;
      case 'typing':
        return PresenceStatus.typing;
      default:
        return PresenceStatus.offline;
    }
  }

  static String _statusToString(PresenceStatus status) {
    return status.name;
  }

  PresenceModel copyWith({
    String? userId,
    PresenceStatus? status,
    DateTime? lastSeen,
    bool? isTyping,
    String? typingInChatId,
    DateTime? lastTypingAt,
  }) {
    return PresenceModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      typingInChatId: typingInChatId ?? this.typingInChatId,
      lastTypingAt: lastTypingAt ?? this.lastTypingAt,
    );
  }

  @override
  String toString() {
    return 'PresenceModel(userId: $userId, status: $status, lastSeen: $lastSeen, isTyping: $isTyping)';
  }
}
