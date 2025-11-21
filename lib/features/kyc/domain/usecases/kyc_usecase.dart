import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/kyc_repository_impl.dart';

class KycUseCase {
  final kycRepo = KycRepositoryImpl();

  Future<Either<Failure, void>> submitKyc({
    required String userId,
    required String fullName,
    required DateTime dateOfBirth,
    required String phoneNumber,
    required String email,
    required String address,
    required String city,
    required String country,
    required String postalCode,
    String? governmentIdNumber,
    String? idType,
    String? governmentIdUrl,
    String? selfieWithIdUrl,
    String? proofOfAddressUrl,
  }) {
    return kycRepo.submitKyc(
      userId: userId,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
      email: email,
      address: address,
      city: city,
      country: country,
      postalCode: postalCode,
      governmentIdNumber: governmentIdNumber,
      idType: idType,
      governmentIdUrl: governmentIdUrl,
      selfieWithIdUrl: selfieWithIdUrl,
      proofOfAddressUrl: proofOfAddressUrl,
    );
  }

  Stream<String> watchKycStatus(String userId) {
    return kycRepo.watchKycStatus(userId);
  }
}
