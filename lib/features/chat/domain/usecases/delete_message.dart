import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/message_repository.dart';

class DeleteMessage {
  final MessageRepository repository;

  DeleteMessage(this.repository);

  Future<Either<Failure, void>> call(String messageId) async {
    return await repository.deleteMessage(messageId);
  }
}
