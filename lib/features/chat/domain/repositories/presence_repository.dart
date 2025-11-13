import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/presence_entity.dart';

abstract class PresenceRepository {
  Stream<Either<Failure, PresenceEntity>> watchUserPresence(String userId);
  Future<Either<Failure, void>> updatePresenceStatus(String userId, PresenceStatus status);
  Future<Either<Failure, void>> updateTypingStatus(String userId, String? chatId, bool isTyping);
  Future<Either<Failure, void>> updateLastSeen(String userId);
  Future<Either<Failure, PresenceEntity?>> getUserPresence(String userId);
}
