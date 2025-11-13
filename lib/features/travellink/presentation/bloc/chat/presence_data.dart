import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/presence_entity.dart';

class PresenceData extends Equatable {
  final Map<String, PresenceEntity> presenceByUser;
  final Map<String, Map<String, bool>> typingStatusByChat;
  final Map<String, bool> activePresenceSubscriptions;
  final Map<String, bool> activeTypingSubscriptions;

  const PresenceData({
    this.presenceByUser = const {},
    this.typingStatusByChat = const {},
    this.activePresenceSubscriptions = const {},
    this.activeTypingSubscriptions = const {},
  });

  PresenceEntity? getPresence(String userId) {
    return presenceByUser[userId];
  }

  Map<String, bool> getTypingStatus(String chatId) {
    return typingStatusByChat[chatId] ?? {};
  }

  bool hasActivePresenceSubscription(String userId) {
    return activePresenceSubscriptions[userId] ?? false;
  }

  bool hasActiveTypingSubscription(String chatId) {
    return activeTypingSubscriptions[chatId] ?? false;
  }

  PresenceData copyWith({
    Map<String, PresenceEntity>? presenceByUser,
    Map<String, Map<String, bool>>? typingStatusByChat,
    Map<String, bool>? activePresenceSubscriptions,
    Map<String, bool>? activeTypingSubscriptions,
  }) {
    return PresenceData(
      presenceByUser: presenceByUser ?? this.presenceByUser,
      typingStatusByChat: typingStatusByChat ?? this.typingStatusByChat,
      activePresenceSubscriptions:
          activePresenceSubscriptions ?? this.activePresenceSubscriptions,
      activeTypingSubscriptions:
          activeTypingSubscriptions ?? this.activeTypingSubscriptions,
    );
  }

  PresenceData updatePresence(String userId, PresenceEntity presence) {
    final updatedMap = Map<String, PresenceEntity>.from(presenceByUser);
    updatedMap[userId] = presence;
    return copyWith(presenceByUser: updatedMap);
  }

  PresenceData updateTypingStatus(String chatId, Map<String, bool> typingUsers) {
    final updatedMap = Map<String, Map<String, bool>>.from(typingStatusByChat);
    updatedMap[chatId] = typingUsers;
    return copyWith(typingStatusByChat: updatedMap);
  }

  PresenceData addPresenceSubscription(String userId) {
    final updatedSubs = Map<String, bool>.from(activePresenceSubscriptions);
    updatedSubs[userId] = true;
    return copyWith(activePresenceSubscriptions: updatedSubs);
  }

  PresenceData removePresenceSubscription(String userId) {
    final updatedSubs = Map<String, bool>.from(activePresenceSubscriptions);
    updatedSubs.remove(userId);
    return copyWith(activePresenceSubscriptions: updatedSubs);
  }

  PresenceData addTypingSubscription(String chatId) {
    final updatedSubs = Map<String, bool>.from(activeTypingSubscriptions);
    updatedSubs[chatId] = true;
    return copyWith(activeTypingSubscriptions: updatedSubs);
  }

  PresenceData removeTypingSubscription(String chatId) {
    final updatedSubs = Map<String, bool>.from(activeTypingSubscriptions);
    updatedSubs.remove(chatId);
    return copyWith(activeTypingSubscriptions: updatedSubs);
  }

  @override
  List<Object?> get props => [
        presenceByUser,
        typingStatusByChat,
        activePresenceSubscriptions,
        activeTypingSubscriptions,
      ];
}
