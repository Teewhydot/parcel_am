import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/kyc_entity.dart';
import '../repositories/kyc_repository.dart';

class SubmitKycUseCase {
  final KycRepository repository;

  SubmitKycUseCase(this.repository);

  Future<Either<Failure, KycEntity>> call(SubmitKycParams params) async {
    return await repository.submitKyc(
      params.userId,
      params.documentUrls,
      params.metadata,
    );
  }
}

class SubmitKycParams extends Equatable {
  final String userId;
  final List<String> documentUrls;
  final Map<String, dynamic>? metadata;

  const SubmitKycParams({
    required this.userId,
    required this.documentUrls,
    this.metadata,
  });

  @override
  List<Object?> get props => [userId, documentUrls, metadata];
}
