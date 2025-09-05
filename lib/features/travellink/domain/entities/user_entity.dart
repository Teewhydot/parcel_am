import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String phoneNumber;
  final bool isVerified;
  final String verificationStatus;
  final DateTime createdAt;
  final Map<String, dynamic> additionalData;
  final String? profilePhotoUrl;
  final double? rating;
  final int? completedDeliveries;
  final int? packagesSent;
  final double? totalEarnings;

  const UserEntity({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.isVerified,
    required this.verificationStatus,
    required this.createdAt,
    required this.additionalData,
    this.profilePhotoUrl,
    this.rating,
    this.completedDeliveries,
    this.packagesSent,
    this.totalEarnings,
  });

  UserEntity copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    bool? isVerified,
    String? verificationStatus,
    DateTime? createdAt,
    Map<String, dynamic>? additionalData,
    String? profilePhotoUrl,
    double? rating,
    int? completedDeliveries,
    int? packagesSent,
    double? totalEarnings,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      additionalData: additionalData ?? this.additionalData,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      rating: rating ?? this.rating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      packagesSent: packagesSent ?? this.packagesSent,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        phoneNumber,
        isVerified,
        verificationStatus,
        createdAt,
        additionalData,
        profilePhotoUrl,
        rating,
        completedDeliveries,
        packagesSent,
        totalEarnings,
      ];
}