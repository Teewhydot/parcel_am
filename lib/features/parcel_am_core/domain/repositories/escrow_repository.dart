import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';

abstract class EscrowRepository {
  Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId);
  Stream<Either<Failure, EscrowEntity?>> watchEscrowByParcel(String parcelId);
  Future<Either<Failure, EscrowEntity>> createEscrow(
    String parcelId,
    String senderId,
    String travelerId,
    double amount,
    String currency,
  );
  Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId);
  Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId);
  Future<Either<Failure, EscrowEntity>> cancelEscrow(String escrowId, String reason);
  Future<Either<Failure, List<EscrowEntity>>> getUserEscrows(String userId);
  Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId);
}
