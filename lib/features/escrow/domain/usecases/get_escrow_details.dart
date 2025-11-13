import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class GetEscrowDetails {
  final EscrowRepository repository;

  GetEscrowDetails(this.repository);

  Future<Either<Failure, EscrowEntity>> call(String escrowId) async {
    return await repository.getEscrowDetails(escrowId);
  }
}
