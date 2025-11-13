import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

class ChatUseCase {
  final ChatRepository repository;

  ChatUseCase(this.repository);

  Stream<Either<Failure, List<Message>>> getMessagesStream(String chatId) {
    return repository.getMessagesStream(chatId);
  }

  Future<Either<Failure, void>> sendMessage(Message message) {
    return repository.sendMessage(message);
  }

  Future<Either<Failure, void>> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) {
    return repository.updateMessageStatus(messageId, status);
  }

  Future<Either<Failure, void>> markMessageAsRead(
    String chatId,
    String messageId,
    String userId,
  ) {
    return repository.markMessageAsRead(chatId, messageId, userId);
  }

  Future<Either<Failure, String>> uploadMedia(
    String filePath,
    String chatId,
    MessageType type,
    Function(double) onProgress,
  ) {
    return repository.uploadMedia(filePath, chatId, type, onProgress);
  }

  Future<Either<Failure, void>> setTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) {
    return repository.setTypingStatus(chatId, userId, isTyping);
  }

  Future<Either<Failure, void>> updateLastSeen(String chatId, String userId) {
    return repository.updateLastSeen(chatId, userId);
  }

  Stream<Either<Failure, Chat>> getChatStream(String chatId) {
    return repository.getChatStream(chatId);
  }

  Future<Either<Failure, void>> deleteMessage(String messageId) {
    return repository.deleteMessage(messageId);
  }
}
