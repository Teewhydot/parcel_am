import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../entities/message_type.dart';
import '../entities/presence_entity.dart';

abstract class MessageRepository {
  Future<Either<Failure, MessageEntity>> sendMessage(
    String chatId,
    String senderId,
    String content,
    MessageType type,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  );

  Future<Either<Failure, List<MessageEntity>>> getMessages(
    String chatId, {
    int? limit,
    String? startAfterMessageId,
  });

  Stream<List<MessageEntity>> watchMessages(String chatId);

  Future<Either<Failure, void>> markAsRead(
    String chatId,
    String userId,
    String messageId,
  );

  Future<Either<Failure, void>> deleteMessage(String messageId);

  Future<Either<Failure, void>> updatePresence(
    String userId,
    bool isOnline,
    bool isTyping,
    String? typingInChatId,
  );

  Stream<PresenceEntity> watchPresence(String userId);

  /// Load older messages for pagination
  /// [beforePageNumber] - load messages from pages before this page number
  Future<Either<Failure, List<MessageEntity>>> loadOlderMessages(
    String chatId, {
    int? beforePageNumber,
  });

  /// Check if there are older message pages available
  Future<Either<Failure, bool>> hasOlderMessages(
    String chatId,
    int currentPageNumber,
  );
}
