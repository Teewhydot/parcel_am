import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class GetEscrowDetails {
  final EscrowRepository _repository;

  GetEscrowDetails({EscrowRepository? repository})
      : _repository = repository ?? GetIt.instance<EscrowRepository>();

  Future<Either<Failure, EscrowEntity>> call(String escrowId) async {
    return await _repository.getEscrowDetails(escrowId);
  }
}
