import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class EscrowUseCase {
  final EscrowRepository repository;

  EscrowUseCase(this.repository);

  Future<Either<Failure, EscrowEntity>> createEscrow({
    required String parcelId,
    required String senderId,
    required String travelerId,
    required double amount,
    String currency = 'NGN',
  }) {
    return repository.createEscrow(
      parcelId,
      senderId,
      travelerId,
      amount,
      currency,
    );
  }

  Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId) {
    return repository.holdEscrow(escrowId);
  }

  Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId) {
    return repository.releaseEscrow(escrowId);
  }

  Future<Either<Failure, EscrowEntity>> cancelEscrow(
    String escrowId,
    String reason,
  ) {
    return repository.cancelEscrow(escrowId, reason);
  }

  Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId) {
    return repository.getEscrow(escrowId);
  }

  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId) {
    return repository.watchEscrowStatus(escrowId);
  }

  Future<Either<Failure, List<EscrowEntity>>> getUserEscrows(String userId) {
    return repository.getUserEscrows(userId);
  }
}
