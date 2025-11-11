import '../../domain/entities/kyc_entity.dart';
import '../../domain/entities/kyc_status.dart';

class KycModel extends KycEntity {
  const KycModel({
    required super.userId,
    required super.status,
    required super.documentUrls,
    super.rejectionReason,
    required super.submittedAt,
    super.reviewedAt,
    super.metadata,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) {
    return KycModel(
      userId: json['userId'] as String,
      status: _statusFromString(json['status'] as String),
      documentUrls: (json['documentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': _statusToString(status),
      'documentUrls': documentUrls,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory KycModel.fromEntity(KycEntity entity) {
    return KycModel(
      userId: entity.userId,
      status: entity.status,
      documentUrls: entity.documentUrls,
      rejectionReason: entity.rejectionReason,
      submittedAt: entity.submittedAt,
      reviewedAt: entity.reviewedAt,
      metadata: entity.metadata,
    );
  }

  KycEntity toEntity() {
    return KycEntity(
      userId: userId,
      status: status,
      documentUrls: documentUrls,
      rejectionReason: rejectionReason,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      metadata: metadata,
    );
  }

  @override
  KycModel copyWith({
    String? userId,
    KycStatus? status,
    List<String>? documentUrls,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    Map<String, dynamic>? metadata,
  }) {
    return KycModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      documentUrls: documentUrls ?? this.documentUrls,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static KycStatus _statusFromString(String status) {
    switch (status) {
      case 'nokyc':
        return KycStatus.nokyc;
      case 'pending':
        return KycStatus.pending;
      case 'approved':
        return KycStatus.approved;
      case 'rejectedkyc':
        return KycStatus.rejectedkyc;
      default:
        return KycStatus.nokyc;
    }
  }

  static String _statusToString(KycStatus status) {
    switch (status) {
      case KycStatus.nokyc:
        return 'nokyc';
      case KycStatus.pending:
        return 'pending';
      case KycStatus.approved:
        return 'approved';
      case KycStatus.rejectedkyc:
        return 'rejectedkyc';
    }
  }
}
