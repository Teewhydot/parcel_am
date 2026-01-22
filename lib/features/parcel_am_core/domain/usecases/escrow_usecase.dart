import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class EscrowUseCase {
  final EscrowRepository _repository;

  EscrowUseCase({EscrowRepository? repository})
      : _repository = repository ?? GetIt.instance<EscrowRepository>();

  Future<Either<Failure, EscrowEntity>> createEscrow({
    required String parcelId,
    required String senderId,
    required String travelerId,
    required double amount,
    String currency = 'NGN',
  }) {
    return _repository.createEscrow(
      parcelId,
      senderId,
      travelerId,
      amount,
      currency,
    );
  }

  Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId) {
    return _repository.holdEscrow(escrowId);
  }

  Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId) {
    return _repository.releaseEscrow(escrowId);
  }

  Future<Either<Failure, EscrowEntity>> cancelEscrow(
    String escrowId,
    String reason,
  ) {
    return _repository.cancelEscrow(escrowId, reason);
  }

  Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId) {
    return _repository.getEscrow(escrowId);
  }

  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId) {
    return _repository.watchEscrowStatus(escrowId);
  }

  Future<Either<Failure, List<EscrowEntity>>> getUserEscrows(String userId) {
    return _repository.getUserEscrows(userId);
  }
}
