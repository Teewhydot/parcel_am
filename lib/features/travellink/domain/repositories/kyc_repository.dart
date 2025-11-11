import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class KycRepository {
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
  });

  Future<Either<Failure, String>> getKycStatus(String userId);

  Stream<String> watchKycStatus(String userId);
}
