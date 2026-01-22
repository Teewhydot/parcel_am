import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/kyc_repository.dart';

class KycUseCase {
  final KycRepository _repository;

  KycUseCase({KycRepository? repository})
      : _repository = repository ?? GetIt.instance<KycRepository>();

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
    return _repository.submitKyc(
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
    return _repository.watchKycStatus(userId);
  }
}
