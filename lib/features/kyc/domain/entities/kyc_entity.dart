import 'package:equatable/equatable.dart';
import 'kyc_status.dart';

class KycEntity extends Equatable {
  // User identification
  final String userId;
  final KycStatus status;

  // Personal Information
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String email;

  // Address Information
  final String address;
  final String city;
  final String country;
  final String postalCode;

  // Government ID Information
  final String? governmentIdNumber;
  final String? idType; // passport, driver_license, national_id

  // Document URLs
  final String? governmentIdUrl;
  final String? selfieWithIdUrl;
  final String? proofOfAddressUrl;

  // Legacy field for backward compatibility
  @Deprecated('Use specific document URLs instead')
  final List<String>? documentUrls;

  // Review Information
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final Map<String, dynamic>? metadata;

  const KycEntity({
    required this.userId,
    required this.status,
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
    this.documentUrls,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.metadata,
  });

  KycEntity copyWith({
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
    return KycEntity(
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

  @override
  List<Object?> get props => [
        userId,
        status,
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
        documentUrls,
        rejectionReason,
        submittedAt,
        reviewedAt,
        metadata,
      ];
}
