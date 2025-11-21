import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final remoteDataSource = GetIt.instance<KycRemoteDataSource>();

  @override
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
  }) async {
    try {
      await remoteDataSource.submitKyc(
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
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(failureMessage: e.toString()));
    }
  }


  @override
  Stream<String> watchKycStatus(String userId) {
    return remoteDataSource.watchKycStatus(userId);
  }
}
