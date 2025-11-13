import 'package:dartz/dartz.dart';
import 'package:parcel_am/core/errors/failures.dart';
import '../entities/escrow_entity.dart';

abstract class EscrowRepository {
  Future<Either<Failure, EscrowEntity>> createEscrow({
    required String senderId,
    required String receiverId,
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, EscrowEntity>> holdFunds(String escrowId);

  Future<Either<Failure, EscrowEntity>> releaseFunds(String escrowId);

  Future<Either<Failure, EscrowEntity>> cancelEscrow(String escrowId);

  Future<Either<Failure, EscrowEntity>> getEscrowDetails(String escrowId);

  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId);
}
