import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/kyc_repository.dart';

class SubmitKycUseCase {
  final KycRepository repository;

  SubmitKycUseCase(this.repository);

  Future<Either<Failure, void>> call(SubmitKycParams params) async {
    return await repository.submitKyc(
      userId: params.userId,
      fullName: params.fullName,
      dateOfBirth: params.dateOfBirth,
      address: params.address,
      idType: params.idType,
      idNumber: params.idNumber,
      frontImagePath: params.frontImagePath,
      backImagePath: params.backImagePath,
      selfieImagePath: params.selfieImagePath,
    );
  }
}

class SubmitKycParams extends Equatable {
  final String userId;
  final String fullName;
  final String dateOfBirth;
  final String address;
  final String idType;
  final String idNumber;
  final String frontImagePath;
  final String backImagePath;
  final String selfieImagePath;

  const SubmitKycParams({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    required this.idType,
    required this.idNumber,
    required this.frontImagePath,
    required this.backImagePath,
    required this.selfieImagePath,
  });

  @override
  List<Object> get props => [
        userId,
        fullName,
        dateOfBirth,
        address,
        idType,
        idNumber,
        frontImagePath,
        backImagePath,
        selfieImagePath,
      ];
}
