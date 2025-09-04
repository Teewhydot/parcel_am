class UserModel {
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

  UserModel({
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

  UserModel copyWith({
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
    return UserModel(
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

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt.toIso8601String(),
      'additionalData': additionalData,
      'profilePhotoUrl': profilePhotoUrl,
      'rating': rating,
      'completedDeliveries': completedDeliveries,
      'packagesSent': packagesSent,
      'totalEarnings': totalEarnings,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      isVerified: json['isVerified'],
      verificationStatus: json['verificationStatus'],
      createdAt: DateTime.parse(json['createdAt']),
      additionalData: json['additionalData'] ?? {},
      profilePhotoUrl: json['profilePhotoUrl'],
      rating: json['rating']?.toDouble(),
      completedDeliveries: json['completedDeliveries'],
      packagesSent: json['packagesSent'],
      totalEarnings: json['totalEarnings']?.toDouble(),
    );
  }
}