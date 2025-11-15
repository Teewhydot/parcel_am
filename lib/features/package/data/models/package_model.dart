import '../../domain/entities/package_entity.dart';

class PackageModel {
  final String id;
  final String senderId;
  final String? travelerId;
  final String origin;
  final String destination;
  final String status;
  final double progress;
  final DateTime? deliveredAt;
  final Map<String, dynamic>? paymentInfo;
  final String? confirmationCode;
  final String? disputeId;

  PackageModel({
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

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      travelerId: map['travelerId'] as String?,
      origin: map['origin'] as String,
      destination: map['destination'] as String,
      status: map['status'] as String,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'].toString())
          : null,
      paymentInfo: map['paymentInfo'] as Map<String, dynamic>?,
      confirmationCode: map['confirmationCode'] as String?,
      disputeId: map['disputeId'] as String?,
    );
  }

  PackageEntity toEntity() {
    return PackageEntity(
      id: id,
      senderId: senderId,
      travelerId: travelerId,
      origin: origin,
      destination: destination,
      status: status,
      progress: progress,
      deliveredAt: deliveredAt,
      paymentInfo: paymentInfo != null ? _parsePaymentInfo(paymentInfo!) : null,
      confirmationCode: confirmationCode,
      disputeId: disputeId,
    );
  }

  PaymentInfo? _parsePaymentInfo(Map<String, dynamic> map) {
    return PaymentInfo(
      isEscrow: map['isEscrow'] as bool? ?? false,
      escrowStatus: map['escrowStatus'] as String?,
      escrowReleaseDate: map['escrowReleaseDate'] != null
          ? DateTime.parse(map['escrowReleaseDate'].toString())
          : null,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
