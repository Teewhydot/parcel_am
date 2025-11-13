import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/chat/data/models/chat_model.dart';

void main() {
  group('ChatModel', () {
    test('should create a valid ChatModel from entity', () {
      final now = DateTime.now();
      final chatModel = ChatModel(
        id: 'chat1',
        participantIds: ['user1', 'user2'],
        participantInfo: {'user1': 'John', 'user2': 'Jane'},
        lastMessage: 'Hello',
        lastMessageSenderId: 'user1',
        lastMessageAt: now,
        unreadCount: {'user1': 0, 'user2': 1},
        createdAt: now,
        updatedAt: now,
        chatType: 'direct',
      );

      expect(chatModel.id, 'chat1');
      expect(chatModel.participantIds.length, 2);
      expect(chatModel.lastMessage, 'Hello');
    });
  });
}
