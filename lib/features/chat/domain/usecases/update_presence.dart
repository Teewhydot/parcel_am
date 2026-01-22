import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/message_repository.dart';

class UpdatePresence {
  final MessageRepository _repository;

  UpdatePresence({MessageRepository? repository})
      : _repository = repository ?? GetIt.instance<MessageRepository>();

  Future<Either<Failure, void>> call(UpdatePresenceParams params) async {
    return await _repository.updatePresence(
      params.userId,
      params.isOnline,
      params.isTyping,
      params.typingInChatId,
    );
  }
}

class UpdatePresenceParams extends Equatable {
  final String userId;
  final bool isOnline;
  final bool isTyping;
  final String? typingInChatId;

  const UpdatePresenceParams({
    required this.userId,
    required this.isOnline,
    required this.isTyping,
    this.typingInChatId,
  });

  @override
  List<Object?> get props => [userId, isOnline, isTyping, typingInChatId];
}
