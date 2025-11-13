import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class GetMessages {
  final MessageRepository repository;

  GetMessages(this.repository);

  Future<Either<Failure, List<MessageEntity>>> call(
    GetMessagesParams params,
  ) async {
    return await repository.getMessages(
      params.chatId,
      limit: params.limit,
      startAfterMessageId: params.startAfterMessageId,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String chatId;
  final int? limit;
  final String? startAfterMessageId;

  const GetMessagesParams({
    required this.chatId,
    this.limit,
    this.startAfterMessageId,
  });

  @override
  List<Object?> get props => [chatId, limit, startAfterMessageId];
}
