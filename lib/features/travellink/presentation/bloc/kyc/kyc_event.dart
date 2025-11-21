import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  const KycEvent();

  @override
  List<Object?> get props => [];
}

class KycSubmitRequested extends KycEvent {
  final String fullName;
  final String dateOfBirth;
  final String address;
  final String idType;
  final String idNumber;
  final String frontImagePath;
  final String backImagePath;
  final String selfieImagePath;

  const KycSubmitRequested({
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

class KycStatusRequested extends KycEvent {
  const KycStatusRequested();
}

class KycStatusUpdated extends KycEvent {
  final String status;

  const KycStatusUpdated(this.status);

  @override
  List<Object> get props => [status];
}

class KycResubmitRequested extends KycEvent {
  final String fullName;
  final String dateOfBirth;
  final String address;
  final String idType;
  final String idNumber;
  final String frontImagePath;
  final String backImagePath;
  final String selfieImagePath;

  const KycResubmitRequested({
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

class KycDocumentUploadProgressUpdated extends KycEvent {
  final String documentType;
  final double progress;

  const KycDocumentUploadProgressUpdated({
    required this.documentType,
    required this.progress,
  });

  @override
  List<Object> get props => [documentType, progress];
}

class KycDocumentUploadCompleted extends KycEvent {
  final String documentType;
  final String downloadUrl;

  const KycDocumentUploadCompleted({
    required this.documentType,
    required this.downloadUrl,
  });

  @override
  List<Object> get props => [documentType, downloadUrl];
}

class KycDocumentUploadFailed extends KycEvent {
  final String documentType;
  final String error;

  const KycDocumentUploadFailed({
    required this.documentType,
    required this.error,
  });

  @override
  List<Object> get props => [documentType, error];
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
