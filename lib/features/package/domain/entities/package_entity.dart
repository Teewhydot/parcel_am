import 'package:equatable/equatable.dart';

class PackageEntity extends Equatable {
  final String id;
  final String senderId;
  final String? travelerId;
  final String origin;
  final String destination;
  final String status;
  final double progress;
  final DateTime? deliveredAt;
  final PaymentInfo? paymentInfo;
  final String? confirmationCode;
  final String? disputeId;

  const PackageEntity({
    required this.id,
    required this.senderId,
    this.travelerId,
    required this.origin,
    required this.destination,
    required this.status,
    this.progress = 0.0,
    this.deliveredAt,
    this.paymentInfo,
    this.confirmationCode,
    this.disputeId,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        travelerId,
        origin,
        destination,
        status,
        progress,
        deliveredAt,
        paymentInfo,
        confirmationCode,
        disputeId,
      ];
}

class PaymentInfo extends Equatable {
  final bool isEscrow;
  final String? escrowStatus;
  final DateTime? escrowReleaseDate;
  final double amount;

  const PaymentInfo({
    required this.isEscrow,
    this.escrowStatus,
    this.escrowReleaseDate,
    required this.amount,
  });

  @override
  List<Object?> get props => [
        isEscrow,
        escrowStatus,
        escrowReleaseDate,
        amount,
      ];
}
