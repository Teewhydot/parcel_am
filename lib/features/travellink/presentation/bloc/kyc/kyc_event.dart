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
