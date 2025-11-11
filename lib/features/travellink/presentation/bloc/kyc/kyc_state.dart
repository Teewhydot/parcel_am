import 'package:equatable/equatable.dart';

abstract class KycState extends Equatable {
  const KycState();

  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {
  const KycInitial();
}

class KycLoading extends KycState {
  final String message;

  const KycLoading({this.message = 'Processing...'});

  @override
  List<Object> get props => [message];
}

class KycSubmitted extends KycState {
  final String status;
  final DateTime submittedAt;

  const KycSubmitted({
    required this.status,
    required this.submittedAt,
  });

  @override
  List<Object> get props => [status, submittedAt];
}

class KycApproved extends KycState {
  final DateTime approvedAt;

  const KycApproved({required this.approvedAt});

  @override
  List<Object> get props => [approvedAt];
}

class KycRejected extends KycState {
  final String reason;
  final DateTime rejectedAt;

  const KycRejected({
    required this.reason,
    required this.rejectedAt,
  });

  @override
  List<Object> get props => [reason, rejectedAt];
}

class KycError extends KycState {
  final String errorMessage;
  final String errorCode;

  const KycError({
    required this.errorMessage,
    this.errorCode = 'kyc_error',
  });

  @override
  List<Object> get props => [errorMessage, errorCode];
}
