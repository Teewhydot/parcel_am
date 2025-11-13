import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class WatchEscrowStatus {
  final EscrowRepository repository;

  WatchEscrowStatus(this.repository);

  Stream<Either<Failure, EscrowEntity>> call(String escrowId) {
    return repository.watchEscrowStatus(escrowId);
  }
}
