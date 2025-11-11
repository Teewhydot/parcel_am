import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/kyc_entity.dart';

abstract class KycRepository {
  Future<Either<Failure, KycEntity>> submitKyc(
    String userId,
    List<String> documentUrls,
    Map<String, dynamic>? metadata,
  );

  Future<Either<Failure, KycEntity>> getKycStatus(String userId);

  Stream<KycEntity> watchKycStatus(String userId);
}
