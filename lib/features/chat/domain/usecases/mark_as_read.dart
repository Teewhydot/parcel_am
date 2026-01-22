import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/message_repository.dart';

class MarkAsRead {
  final MessageRepository _repository;

  MarkAsRead({MessageRepository? repository})
      : _repository = repository ?? GetIt.instance<MessageRepository>();

  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    return await _repository.markAsRead(
      params.chatId,
      params.userId,
      params.messageId,
    );
  }
}

class MarkAsReadParams extends Equatable {
  final String chatId;
  final String userId;
  final String messageId;

  const MarkAsReadParams({
    required this.chatId,
    required this.userId,
    required this.messageId,
  });

  @override
  List<Object?> get props => [chatId, userId, messageId];
}
