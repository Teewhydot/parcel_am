import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/features/chat/data/models/chat_model.dart';

void main() {
  group('ChatModel', () {
    test('should create a valid ChatModel from entity', () {
      final now = DateTime.now();
      final chatModel = ChatModel(
        id: 'chat1',
        participantIds: ['user1', 'user2'],
        participantNames: {'user1': 'John', 'user2': 'Jane'},
        participantAvatars: {'user1': null, 'user2': null},
        lastMessage: null,
        lastMessageTime: now,
        unreadCount: {'user1': 0, 'user2': 1},
        isTyping: {'user1': false, 'user2': false},
        lastSeen: {'user1': now, 'user2': now},
        createdAt: now,
      );

      expect(chatModel.id, 'chat1');
      expect(chatModel.participantIds.length, 2);
      expect(chatModel.participantNames['user1'], 'John');
    });
  });
}
