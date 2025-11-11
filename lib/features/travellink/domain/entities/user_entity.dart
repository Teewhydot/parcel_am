import 'package:equatable/equatable.dart';

enum KycStatus {
  notStarted,
  incomplete,
  pending,
  underReview,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case KycStatus.notStarted:
        return 'Not Started';
      case KycStatus.incomplete:
        return 'Incomplete';
      case KycStatus.pending:
        return 'Pending';
      case KycStatus.underReview:
        return 'Under Review';
      case KycStatus.approved:
        return 'Approved';
      case KycStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isVerified => this == KycStatus.approved;
  bool get requiresAction => this == KycStatus.notStarted || this == KycStatus.incomplete || this == KycStatus.rejected;
}

class UserEntity extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final bool isVerified;
  final String verificationStatus;
  final KycStatus kycStatus;
  final DateTime createdAt;
  final Map<String, dynamic> additionalData;
  final String? profilePhotoUrl;
  final double? rating;
  final int? completedDeliveries;
  final int? packagesSent;
  final double? totalEarnings;
  final double? availableBalance;
  final double? pendingBalance;
  final String kycStatus;

  const UserEntity({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.isVerified,
    required this.verificationStatus,
    this.kycStatus = KycStatus.notStarted,
    required this.createdAt,
    required this.additionalData,
    this.profilePhotoUrl,
    this.rating,
    this.completedDeliveries,
    this.packagesSent,
    this.totalEarnings,
    this.availableBalance,
    this.pendingBalance,
    this.kycStatus = 'not_submitted',
  });

  UserEntity copyWith({
    String? uid,
    String? displayName,
    String? email,
    bool? isVerified,
    String? verificationStatus,
    KycStatus? kycStatus,
    DateTime? createdAt,
    Map<String, dynamic>? additionalData,
    String? profilePhotoUrl,
    double? rating,
    int? completedDeliveries,
    int? packagesSent,
    double? totalEarnings,
    double? availableBalance,
    double? pendingBalance,
    String? kycStatus,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      kycStatus: kycStatus ?? this.kycStatus,
      createdAt: createdAt ?? this.createdAt,
      additionalData: additionalData ?? this.additionalData,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      rating: rating ?? this.rating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      packagesSent: packagesSent ?? this.packagesSent,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        isVerified,
        verificationStatus,
        kycStatus,
        createdAt,
        additionalData,
        profilePhotoUrl,
        rating,
        completedDeliveries,
        packagesSent,
        totalEarnings,
        availableBalance,
        pendingBalance,
        kycStatus,
      ];
}