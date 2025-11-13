import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../failures/failures.dart';
import '../../entities/chat/message_entity.dart';
import '../../repositories/chat/chat_repository.dart';

class MessageUseCase {
  final ChatRepository _repository;

  MessageUseCase([ChatRepository? repository])
      : _repository = repository ?? GetIt.instance<ChatRepository>();

  Stream<Either<Failure, List<MessageEntity>>> watchMessages(String chatId) {
    return _repository.watchMessages(chatId);
  }

  Future<Either<Failure, MessageEntity>> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
  }) {
    return _repository.sendMessage(
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      replyToId: replyToId,
    );
  }

  Future<Either<Failure, void>> deleteMessage(String messageId) {
    return _repository.deleteMessage(messageId);
  }
}
