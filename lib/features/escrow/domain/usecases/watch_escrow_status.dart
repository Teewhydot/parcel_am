import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class WatchEscrowStatus {
  final EscrowRepository _repository;

  WatchEscrowStatus({EscrowRepository? repository})
      : _repository = repository ?? GetIt.instance<EscrowRepository>();

  Stream<Either<Failure, EscrowEntity>> call(String escrowId) {
    return _repository.watchEscrowStatus(escrowId);
  }
}
