import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class HoldBalanceForEscrowUseCase {
  final WalletRepository repository;

  HoldBalanceForEscrowUseCase(this.repository);

  Future<Either<Failure, WalletEntity>> call(HoldEscrowParams params) async {
    return await repository.holdBalanceForEscrow(
      userId: params.userId,
      amount: params.amount,
      orderId: params.orderId,
    );
  }
}

class HoldEscrowParams extends Equatable {
  final String userId;
  final double amount;
  final String orderId;

  const HoldEscrowParams({
    required this.userId,
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object> get props => [userId, amount, orderId];
}
