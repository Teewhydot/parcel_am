import 'package:flutter/material.dart';

class VerificationModel {
  final String userId;
  final PersonalInfo personalInfo;
  final IdentityDocuments identityDocuments;
  final AddressInfo addressInfo;
  final String status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final int currentStep;

  VerificationModel({
    required this.userId,
    required this.personalInfo,
    required this.identityDocuments,
    required this.addressInfo,
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    required this.currentStep,
  });

  VerificationModel copyWith({
    String? userId,
    PersonalInfo? personalInfo,
    IdentityDocuments? identityDocuments,
    AddressInfo? addressInfo,
    String? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    int? currentStep,
  }) {
    return VerificationModel(
      userId: userId ?? this.userId,
      personalInfo: personalInfo ?? this.personalInfo,
      identityDocuments: identityDocuments ?? this.identityDocuments,
      addressInfo: addressInfo ?? this.addressInfo,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class PersonalInfo {
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String? nin;
  final String? bvn;
  final String phoneNumber;
  final String email;

  PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.nin,
    this.bvn,
    required this.phoneNumber,
    required this.email,
  });

  PersonalInfo copyWith({
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? gender,
    String? nin,
    String? bvn,
    String? phoneNumber,
    String? email,
  }) {
    return PersonalInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nin: nin ?? this.nin,
      bvn: bvn ?? this.bvn,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }
}

class IdentityDocuments {
  final DocumentUpload? governmentId;
  final DocumentUpload? selfieWithId;
  final DocumentUpload? proofOfAddress;

  IdentityDocuments({
    this.governmentId,
    this.selfieWithId,
    this.proofOfAddress,
  });

  IdentityDocuments copyWith({
    DocumentUpload? governmentId,
    DocumentUpload? selfieWithId,
    DocumentUpload? proofOfAddress,
  }) {
    return IdentityDocuments(
      governmentId: governmentId ?? this.governmentId,
      selfieWithId: selfieWithId ?? this.selfieWithId,
      proofOfAddress: proofOfAddress ?? this.proofOfAddress,
    );
  }
}

class AddressInfo {
  final String streetAddress;
  final String city;
  final String state;
  final String? postalCode;
  final String country;

  AddressInfo({
    required this.streetAddress,
    required this.city,
    required this.state,
    this.postalCode,
    required this.country,
  });

  AddressInfo copyWith({
    String? streetAddress,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return AddressInfo(
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }
}

class DocumentUpload {
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final DateTime uploadedAt;
  final String status;

  DocumentUpload({
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    required this.uploadedAt,
    required this.status,
  });
}

class VerificationStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const VerificationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<VerificationStep> steps = [
    VerificationStep(
      id: 'personal',
      title: 'Personal Information',
      description: 'Basic details about yourself',
      icon: Icons.person_outline,
    ),
    VerificationStep(
      id: 'identity',
      title: 'Identity Verification',
      description: 'Upload your ID documents',
      icon: Icons.badge_outlined,
    ),
    VerificationStep(
      id: 'address',
      title: 'Address Verification',
      description: 'Confirm your address',
      icon: Icons.home_outlined,
    ),
    VerificationStep(
      id: 'review',
      title: 'Review & Submit',
      description: 'Review all information',
      icon: Icons.check_circle_outline,
    ),
  ];
}

