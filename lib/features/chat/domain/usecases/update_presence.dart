import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/message_repository.dart';

class UpdatePresence {
  final MessageRepository repository;

  UpdatePresence(this.repository);

  Future<Either<Failure, void>> call(UpdatePresenceParams params) async {
    return await repository.updatePresence(
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
