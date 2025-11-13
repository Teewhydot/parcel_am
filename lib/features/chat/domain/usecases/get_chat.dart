import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChat {
  final ChatRepository repository;

  GetChat(this.repository);

  Future<Either<Failure, ChatEntity>> call(String chatId) async {
    return await repository.getChat(chatId);
  }
}
