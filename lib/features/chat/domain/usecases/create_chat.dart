import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class CreateChat {
  final ChatRepository repository;

  CreateChat(this.repository);

  Future<Either<Failure, ChatEntity>> call(CreateChatParams params) async {
    return await repository.createChat(
      params.participantIds,
      params.metadata,
    );
  }
}

class CreateChatParams extends Equatable {
  final List<String> participantIds;
  final Map<String, dynamic>? metadata;

  const CreateChatParams({
    required this.participantIds,
    this.metadata,
  });

  @override
  List<Object?> get props => [participantIds, metadata];
}
