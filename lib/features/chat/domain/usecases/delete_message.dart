import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/message_repository.dart';

class DeleteMessage {
  final MessageRepository _repository;

  DeleteMessage({MessageRepository? repository})
      : _repository = repository ?? GetIt.instance<MessageRepository>();

  Future<Either<Failure, void>> call(String messageId) async {
    return await _repository.deleteMessage(messageId);
  }
}
