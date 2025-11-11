import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class ReleaseEscrowBalanceUseCase {
  final WalletRepository repository;

  ReleaseEscrowBalanceUseCase(this.repository);

  Future<Either<Failure, WalletEntity>> call(ReleaseEscrowParams params) async {
    return await repository.releaseEscrowBalance(
      userId: params.userId,
      orderId: params.orderId,
    );
  }
}

class ReleaseEscrowParams extends Equatable {
  final String userId;
  final String orderId;

  const ReleaseEscrowParams({
    required this.userId,
    required this.orderId,
  });

  @override
  List<Object> get props => [userId, orderId];
}
