import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/kyc_repository.dart';

class KycUseCase {
  final KycRepository kycRepo;

  KycUseCase(this.kycRepo);

  Future<Either<Failure, void>> submitKyc({
    required String userId,
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String idType,
    required String idNumber,
    required String frontImagePath,
    required String backImagePath,
    required String selfieImagePath,
  }) {
    return kycRepo.submitKyc(
      userId: userId,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      address: address,
      idType: idType,
      idNumber: idNumber,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
      selfieImagePath: selfieImagePath,
    );
  }


  Stream<String> watchKycStatus(String userId) {
    return kycRepo.watchKycStatus(userId);
  }
}
