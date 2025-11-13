import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetUserChats {
  final ChatRepository repository;

  GetUserChats(this.repository);

  Future<Either<Failure, List<ChatEntity>>> call(String userId) async {
    return await repository.getUserChats(userId);
  }
}
