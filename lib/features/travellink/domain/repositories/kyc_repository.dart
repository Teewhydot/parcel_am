import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class KycRepository {
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
  });
  Stream<String> watchKycStatus(String userId);
}
