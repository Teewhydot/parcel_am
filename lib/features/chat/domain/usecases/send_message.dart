import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../entities/message_type.dart';
import '../repositories/message_repository.dart';

class SendMessage {
  final MessageRepository _repository;

  SendMessage({MessageRepository? repository})
      : _repository = repository ?? GetIt.instance<MessageRepository>();

  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) async {
    return await _repository.sendMessage(
      params.chatId,
      params.senderId,
      params.content,
      params.type,
      params.replyToMessageId,
      params.metadata,
    );
  }
}

class SendMessageParams extends Equatable {
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;

  const SendMessageParams({
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.replyToMessageId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        chatId,
        senderId,
        content,
        type,
        replyToMessageId,
        metadata,
      ];
}
