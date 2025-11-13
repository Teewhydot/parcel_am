import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/escrow_entity.dart';
import '../repositories/escrow_repository.dart';

class CreateEscrow {
  final EscrowRepository repository;

  CreateEscrow(this.repository);

  Future<Either<Failure, EscrowEntity>> call({
    required String senderId,
    required String receiverId,
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    return await repository.createEscrow(
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      currency: currency,
      description: description,
      metadata: metadata,
    );
  }
}
