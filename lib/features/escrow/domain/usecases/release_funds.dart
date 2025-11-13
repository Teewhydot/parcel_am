import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class ReleaseFunds {
  final EscrowRepository repository;

  ReleaseFunds(this.repository);

  Future<Either<Failure, EscrowEntity>> call(String escrowId) async {
    return await repository.releaseFunds(escrowId);
  }
}
