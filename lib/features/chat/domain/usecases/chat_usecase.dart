import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../entities/user_entity.dart';
import '../repositories/chat_repository.dart';

class ChatUseCase {
  final ChatRepository repository;

  ChatUseCase(this.repository);

  Stream<Either<Failure, List<ChatEntity>>> getChatList(String userId) {
    return repository.getChatList(userId);
  }

  Stream<Either<Failure, PresenceStatus>> getPresenceStatus(String userId) {
    return repository.getPresenceStatus(userId);
  }

  Future<Either<Failure, void>> deleteChat(String chatId) {
    return repository.deleteChat(chatId);
  }

  Future<Either<Failure, void>> markAsRead(String chatId) {
    return repository.markAsRead(chatId);
  }

  Future<Either<Failure, void>> togglePin(String chatId, bool isPinned) {
    return repository.togglePin(chatId, isPinned);
  }

  Future<Either<Failure, void>> toggleMute(String chatId, bool isMuted) {
    return repository.toggleMute(chatId, isMuted);
  }

  Future<Either<Failure, List<ChatUserEntity>>> searchUsers(String query) {
    return repository.searchUsers(query);
  }

  Future<Either<Failure, String>> createChat(String currentUserId, String participantId) {
    return repository.createChat(currentUserId, participantId);
  }
}
