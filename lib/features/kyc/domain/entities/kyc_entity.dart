import 'package:equatable/equatable.dart';
import 'kyc_status.dart';

class KycEntity extends Equatable {
  final String userId;
  final KycStatus status;
  final List<String> documentUrls;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final Map<String, dynamic>? metadata;

  const KycEntity({
    required this.userId,
    required this.status,
    required this.documentUrls,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.metadata,
  });

  KycEntity copyWith({
    String? userId,
    KycStatus? status,
    List<String>? documentUrls,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    Map<String, dynamic>? metadata,
  }) {
    return KycEntity(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      documentUrls: documentUrls ?? this.documentUrls,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        status,
        documentUrls,
        rejectionReason,
        submittedAt,
        reviewedAt,
        metadata,
      ];
}
