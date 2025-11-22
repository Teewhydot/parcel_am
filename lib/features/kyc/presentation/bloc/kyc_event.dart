import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  const KycEvent();

  @override
  List<Object?> get props => [];
}

class KycDocumentUploadRequested extends KycEvent {
  final String userId;
  final String documentType;
  final String filePath;

  const KycDocumentUploadRequested({
    required this.userId,
    required this.documentType,
    required this.filePath,
  });

  @override
  List<Object> get props => [userId, documentType, filePath];
}



class KycFinalSubmitRequested extends KycEvent {
  final String userId;
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String email;
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final String? governmentIdNumber;
  final String? idType;
  final String? governmentIdUrl;
  final String? selfieWithIdUrl;
  final String? proofOfAddressUrl;

  const KycFinalSubmitRequested({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.country,
    required this.postalCode,
    this.governmentIdNumber,
    this.idType,
    this.governmentIdUrl,
    this.selfieWithIdUrl,
    this.proofOfAddressUrl,
  });

  @override
  List<Object?> get props => [
        userId,
        fullName,
        dateOfBirth,
        phoneNumber,
        email,
        address,
        city,
        country,
        postalCode,
        governmentIdNumber,
        idType,
        governmentIdUrl,
        selfieWithIdUrl,
        proofOfAddressUrl,
      ];
}
