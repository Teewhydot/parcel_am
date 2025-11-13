import 'package:dartz/dartz.dart';
import '../../failures/failures.dart';
import '../../entities/chat/chat_entity.dart';
import '../../entities/chat/message_entity.dart';
import '../../entities/chat/presence_entity.dart';

abstract class ChatRepository {
  Stream<Either<Failure, List<ChatEntity>>> watchUserChats(String userId);
  
  Stream<Either<Failure, List<MessageEntity>>> watchMessages(String chatId);
  
  Future<Either<Failure, ChatEntity>> createChat(List<String> participantIds);
  
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  });
  
  Future<Either<Failure, void>> deleteMessage(String messageId);
  
  Future<Either<Failure, void>> markAsRead(String chatId, String userId);
  
  Stream<Either<Failure, PresenceEntity>> watchUserPresence(String userId);
  
  Future<Either<Failure, void>> updatePresence({
    required String userId,
    required OnlineStatus status,
    String? currentChatId,
  });
  
  Future<Either<Failure, void>> setTypingStatus({
    required String userId,
    required String chatId,
    required bool isTyping,
  });
  
  Stream<Either<Failure, Map<String, bool>>> watchTypingStatus(String chatId);
}
