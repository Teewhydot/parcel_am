import '../entities/kyc_entity.dart';
import '../repositories/kyc_repository.dart';

class WatchKycStatusUseCase {
  final KycRepository repository;

  WatchKycStatusUseCase(this.repository);

  Stream<KycEntity> call(String userId) {
    return repository.watchKycStatus(userId);
  }
}
