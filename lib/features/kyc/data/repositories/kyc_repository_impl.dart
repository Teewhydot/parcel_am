import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/kyc_entity.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_datasource.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remoteDataSource;

  KycRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, KycEntity>> submitKyc(
    String userId,
    List<String> documentUrls,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final kyc = await remoteDataSource.submitKyc(
        userId,
        documentUrls,
        metadata,
      );
      return Right(kyc);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, KycEntity>> getKycStatus(String userId) async {
    try {
      final kyc = await remoteDataSource.getKycStatus(userId);
      return Right(kyc);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }

  @override
  Stream<KycEntity> watchKycStatus(String userId) {
    return remoteDataSource.watchKycStatus(userId);
  }
}
