import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/message_type.dart';
import '../entities/chat.dart';

abstract class ChatRepository {
  // Chat management
  Future<Either<Failure, Chat>> createChat(List<String> participantIds);
  Future<Either<Failure, Chat>> getChat(String chatId);
  Future<Either<Failure, List<Chat>>> getUserChats(String userId);
  Stream<Chat> watchChat(String chatId);
  Stream<List<Chat>> watchUserChats(String userId);
  Future<Either<Failure, Chat>> getOrCreateChat({
    required String chatId,
    required List<String> participantIds,
    required Map<String, String> participantNames,
  });

  // Message management
  Stream<Either<Failure, List<Message>>> getMessagesStream(String chatId);
  Future<Either<Failure, void>> sendMessage(Message message);
  Future<Either<Failure, void>> updateMessageStatus(
    String messageId,
    MessageStatus status,
  );
  Future<Either<Failure, void>> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  );
  Future<Either<Failure, String>> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  );
  Future<Either<Failure, void>> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  );
  Future<Either<Failure, void>> updateLastSeen(String chatId, String userId);
  Stream<Either<Failure, Chat>> getChatStream(String chatId);
  Future<Either<Failure, void>> deleteMessage(String messageId);
  Future<void> markMessageNotificationSent(String chatId, String messageId);
}
