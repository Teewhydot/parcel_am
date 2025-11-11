import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class ReleaseEscrowBalanceUseCase {
  final WalletRepository repository;

  ReleaseEscrowBalanceUseCase(this.repository);

  Future<Either<Failure, WalletEntity>> call(ReleaseEscrowParams params) async {
    // Since releaseBalance needs an amount, we need to get it from the wallet first
    final walletResult = await repository.getWallet(params.userId);
    return walletResult.fold(
      (failure) => Left(failure),
      (wallet) async {
        // Find the held amount for this order
        final heldAmount = wallet.heldBalance; // Use held balance as it represents held funds
        return await repository.releaseBalance(
          wallet.id,
          heldAmount,
          params.orderId,
        );
      },
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
