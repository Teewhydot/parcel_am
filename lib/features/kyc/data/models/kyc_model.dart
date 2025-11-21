import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/kyc_entity.dart';
import '../../domain/entities/kyc_status.dart';

class KycModel extends KycEntity {
  const KycModel({
    required super.userId,
    required super.status,
    required super.fullName,
    required super.dateOfBirth,
    required super.phoneNumber,
    required super.email,
    required super.address,
    required super.city,
    required super.country,
    required super.postalCode,
    super.governmentIdNumber,
    super.idType,
    super.governmentIdUrl,
    super.selfieWithIdUrl,
    super.proofOfAddressUrl,
    super.documentUrls,
    super.rejectionReason,
    required super.submittedAt,
    super.reviewedAt,
    super.metadata,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) {
    return KycModel(
      userId: json['userId'] as String,
      status: _statusFromString(json['status'] as String),
      fullName: json['fullName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      postalCode: json['postalCode'] as String,
      governmentIdNumber: json['governmentIdNumber'] as String?,
      idType: json['idType'] as String?,
      governmentIdUrl: json['governmentIdUrl'] as String?,
      selfieWithIdUrl: json['selfieWithIdUrl'] as String?,
      proofOfAddressUrl: json['proofOfAddressUrl'] as String?,
      documentUrls: (json['documentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  factory KycModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KycModel(
      userId: doc.id,
      status: _statusFromString(data['status'] as String? ?? 'nokyc'),
      fullName: data['fullName'] as String? ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime.now(),
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      country: data['country'] as String? ?? '',
      postalCode: data['postalCode'] as String? ?? '',
      governmentIdNumber: data['governmentIdNumber'] as String?,
      idType: data['idType'] as String?,
      governmentIdUrl: data['governmentIdUrl'] as String?,
      selfieWithIdUrl: data['selfieWithIdUrl'] as String?,
      proofOfAddressUrl: data['proofOfAddressUrl'] as String?,
      documentUrls: (data['documentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      rejectionReason: data['rejectionReason'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': _statusToString(status),
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'governmentIdNumber': governmentIdNumber,
      'idType': idType,
      'governmentIdUrl': governmentIdUrl,
      'selfieWithIdUrl': selfieWithIdUrl,
      'proofOfAddressUrl': proofOfAddressUrl,
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
      fullName: entity.fullName,
      dateOfBirth: entity.dateOfBirth,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      address: entity.address,
      city: entity.city,
      country: entity.country,
      postalCode: entity.postalCode,
      governmentIdNumber: entity.governmentIdNumber,
      idType: entity.idType,
      governmentIdUrl: entity.governmentIdUrl,
      selfieWithIdUrl: entity.selfieWithIdUrl,
      proofOfAddressUrl: entity.proofOfAddressUrl,
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
    String? fullName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    String? governmentIdNumber,
    String? idType,
    String? governmentIdUrl,
    String? selfieWithIdUrl,
    String? proofOfAddressUrl,
    List<String>? documentUrls,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    Map<String, dynamic>? metadata,
  }) {
    return KycModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      governmentIdNumber: governmentIdNumber ?? this.governmentIdNumber,
      idType: idType ?? this.idType,
      governmentIdUrl: governmentIdUrl ?? this.governmentIdUrl,
      selfieWithIdUrl: selfieWithIdUrl ?? this.selfieWithIdUrl,
      proofOfAddressUrl: proofOfAddressUrl ?? this.proofOfAddressUrl,
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
