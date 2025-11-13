import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory PresenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PresenceModel(
      userId: doc.id,
      status: _statusFromString(data['status'] as String? ?? 'offline'),
      lastSeen: data['lastSeen'] is Timestamp
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
      isTyping: data['isTyping'] as bool? ?? false,
      typingInChatId: data['typingInChatId'] as String?,
      lastTypingAt: data['lastTypingAt'] is Timestamp
          ? (data['lastTypingAt'] as Timestamp).toDate()
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

  Map<String, dynamic> toJson() {
    return {
      'status': _statusToString(status),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isTyping': isTyping,
      'typingInChatId': typingInChatId,
      'lastTypingAt': lastTypingAt != null ? Timestamp.fromDate(lastTypingAt!) : null,
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
      default:
        return PresenceStatus.offline;
    }
  }

  static String _statusToString(PresenceStatus status) {
    return status.name;
  }
}
