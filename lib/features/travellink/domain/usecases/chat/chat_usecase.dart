import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../failures/failures.dart';
import '../../entities/chat/chat_entity.dart';
import '../../entities/chat/message_entity.dart';
import '../../repositories/chat/chat_repository.dart';

class ChatUseCase {
  final ChatRepository _repository;

  ChatUseCase([ChatRepository? repository])
      : _repository = repository ?? GetIt.instance<ChatRepository>();

  Stream<Either<Failure, List<ChatEntity>>> watchUserChats(String userId) {
    return _repository.watchUserChats(userId);
  }

  Future<Either<Failure, ChatEntity>> createChat(List<String> participantIds) {
    return _repository.createChat(participantIds);
  }

  Future<Either<Failure, void>> markAsRead(String chatId, String userId) {
    return _repository.markAsRead(chatId, userId);
  }
}
