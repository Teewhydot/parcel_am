import '../repositories/kyc_repository.dart';

class WatchKycStatusUseCase {
  final KycRepository repository;

  WatchKycStatusUseCase(this.repository);

  Stream<String> call(String userId) {
    return repository.watchKycStatus(userId);
  }
}
