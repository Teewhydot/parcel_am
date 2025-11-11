import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/kyc_entity.dart';
import '../repositories/kyc_repository.dart';

class GetKycStatusUseCase {
  final KycRepository repository;

  GetKycStatusUseCase(this.repository);

  Future<Either<Failure, KycEntity>> call(String userId) async {
    return await repository.getKycStatus(userId);
  }
}
