import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/message_entity.dart';

class MessageData extends Equatable {
  final Map<String, List<MessageEntity>> messagesByChat;
  final Map<String, bool> activeSubscriptions;

  const MessageData({
    this.messagesByChat = const {},
    this.activeSubscriptions = const {},
  });

  List<MessageEntity> getMessages(String chatId) {
    return messagesByChat[chatId] ?? [];
  }

  bool hasActiveSubscription(String chatId) {
    return activeSubscriptions[chatId] ?? false;
  }

  MessageData copyWith({
    Map<String, List<MessageEntity>>? messagesByChat,
    Map<String, bool>? activeSubscriptions,
  }) {
    return MessageData(
      messagesByChat: messagesByChat ?? this.messagesByChat,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
    );
  }

  MessageData updateMessages(String chatId, List<MessageEntity> messages) {
    final updatedMap = Map<String, List<MessageEntity>>.from(messagesByChat);
    updatedMap[chatId] = messages;
    return copyWith(messagesByChat: updatedMap);
  }

  MessageData addSubscription(String chatId) {
    final updatedSubs = Map<String, bool>.from(activeSubscriptions);
    updatedSubs[chatId] = true;
    return copyWith(activeSubscriptions: updatedSubs);
  }

  MessageData removeSubscription(String chatId) {
    final updatedSubs = Map<String, bool>.from(activeSubscriptions);
    updatedSubs.remove(chatId);
    return copyWith(activeSubscriptions: updatedSubs);
  }

  @override
  List<Object?> get props => [messagesByChat, activeSubscriptions];
}
