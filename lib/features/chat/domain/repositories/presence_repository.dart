import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class PresenceRepository {
  Future<Either<Failure, void>> setOnline(String userId);
  Future<Either<Failure, void>> setOffline(String userId);
  Future<Either<Failure, void>> updateLastSeen(String userId);
}
