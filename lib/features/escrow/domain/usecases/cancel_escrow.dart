import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class CancelEscrow {
  final EscrowRepository repository;

  CancelEscrow(this.repository);

  Future<Either<Failure, EscrowEntity>> call(String escrowId) async {
    return await repository.cancelEscrow(escrowId);
  }
}
