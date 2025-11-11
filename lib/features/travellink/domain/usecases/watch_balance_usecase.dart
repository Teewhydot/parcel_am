import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class WatchBalanceUseCase {
  final WalletRepository repository;

  WatchBalanceUseCase(this.repository);

  Stream<WalletEntity> call(String userId) {
    return repository.watchBalance(userId);
  }
}
