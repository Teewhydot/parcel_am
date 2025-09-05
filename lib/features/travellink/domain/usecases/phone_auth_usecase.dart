import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class PhoneAuthUseCase {
  final AuthRepository repository;

  PhoneAuthUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(PhoneAuthParams params) async {
    return await repository.signInWithPhoneNumber(
      params.phoneNumber,
      params.verificationCode,
    );
  }
}

class SendPhoneVerificationUseCase {
  final AuthRepository repository;

  SendPhoneVerificationUseCase(this.repository);

  Future<Either<Failure, void>> call(SendPhoneVerificationParams params) async {
    return await repository.sendPhoneVerificationCode(params.phoneNumber);
  }
}

class PhoneAuthParams extends Equatable {
  final String phoneNumber;
  final String verificationCode;

  const PhoneAuthParams({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  List<Object> get props => [phoneNumber, verificationCode];
}

class SendPhoneVerificationParams extends Equatable {
  final String phoneNumber;

  const SendPhoneVerificationParams({
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [phoneNumber];
}