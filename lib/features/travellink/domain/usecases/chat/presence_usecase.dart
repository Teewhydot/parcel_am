import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../failures/failures.dart';
import '../../entities/chat/presence_entity.dart';
import '../../repositories/chat/chat_repository.dart';

class PresenceUseCase {
  final ChatRepository _repository;

  PresenceUseCase([ChatRepository? repository])
      : _repository = repository ?? GetIt.instance<ChatRepository>();

  Stream<Either<Failure, PresenceEntity>> watchUserPresence(String userId) {
    return _repository.watchUserPresence(userId);
  }

  Future<Either<Failure, void>> updatePresence({
    required String userId,
    required OnlineStatus status,
    String? currentChatId,
  }) {
    return _repository.updatePresence(
      userId: userId,
      status: status,
      currentChatId: currentChatId,
    );
  }

  Future<Either<Failure, void>> setTypingStatus({
    required String userId,
    required String chatId,
    required bool isTyping,
  }) {
    return _repository.setTypingStatus(
      userId: userId,
      chatId: chatId,
      isTyping: isTyping,
    );
  }

  Stream<Either<Failure, Map<String, bool>>> watchTypingStatus(String chatId) {
    return _repository.watchTypingStatus(chatId);
  }
}
