import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remoteDataSource;

  KycRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      await remoteDataSource.submitKyc(
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
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getKycStatus(String userId) async {
    try {
      final status = await remoteDataSource.getKycStatus(userId);
      return Right(status);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<String> watchKycStatus(String userId) {
    return remoteDataSource.watchKycStatus(userId);
  }
}
