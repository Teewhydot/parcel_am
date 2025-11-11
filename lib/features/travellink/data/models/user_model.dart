import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.displayName,
    required super.email,
    required super.isVerified,
    required super.verificationStatus,
    required super.createdAt,
    required super.additionalData,
    super.profilePhotoUrl,
    super.rating,
    super.completedDeliveries,
    super.packagesSent,
    super.totalEarnings,
    super.availableBalance,
    super.pendingBalance,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      isVerified: json['isVerified'],
      verificationStatus: json['verificationStatus'],
      createdAt: DateTime.parse(json['createdAt']),
      additionalData: json['additionalData'] ?? {},
      profilePhotoUrl: json['profilePhotoUrl'],
      rating: json['rating']?.toDouble(),
      completedDeliveries: json['completedDeliveries'],
      packagesSent: json['packagesSent'],
      totalEarnings: json['totalEarnings']?.toDouble(),
      availableBalance: json['availableBalance']?.toDouble(),
      pendingBalance: json['pendingBalance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt.toIso8601String(),
      'additionalData': additionalData,
      'profilePhotoUrl': profilePhotoUrl,
      'rating': rating,
      'completedDeliveries': completedDeliveries,
      'packagesSent': packagesSent,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      displayName: entity.displayName,
      email: entity.email,
      isVerified: entity.isVerified,
      verificationStatus: entity.verificationStatus,
      createdAt: entity.createdAt,
      additionalData: entity.additionalData,
      profilePhotoUrl: entity.profilePhotoUrl,
      rating: entity.rating,
      completedDeliveries: entity.completedDeliveries,
      packagesSent: entity.packagesSent,
      totalEarnings: entity.totalEarnings,
      availableBalance: entity.availableBalance,
      pendingBalance: entity.pendingBalance,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      displayName: displayName,
      email: email,
      isVerified: isVerified,
      verificationStatus: verificationStatus,
      createdAt: createdAt,
      additionalData: additionalData,
      profilePhotoUrl: profilePhotoUrl,
      rating: rating,
      completedDeliveries: completedDeliveries,
      packagesSent: packagesSent,
      totalEarnings: totalEarnings,
      availableBalance: availableBalance,
      pendingBalance: pendingBalance,
    );
  }

  @override
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    bool? isVerified,
    String? verificationStatus,
    DateTime? createdAt,
    Map<String, dynamic>? additionalData,
    String? profilePhotoUrl,
    double? rating,
    int? completedDeliveries,
    int? packagesSent,
    double? totalEarnings,
    double? availableBalance,
    double? pendingBalance,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      additionalData: additionalData ?? this.additionalData,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      rating: rating ?? this.rating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      packagesSent: packagesSent ?? this.packagesSent,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
    );
  }
}