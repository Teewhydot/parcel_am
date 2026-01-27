import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../parcel_am_core/data/constants/verification_constants.dart';
import '../verification_widgets.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.nin,
    required this.bvn,
    required this.address,
    required this.city,
    required this.state,
    required this.hasGovernmentId,
    required this.hasSelfieWithId,
    required this.hasProofOfAddress,
  });

  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String nin;
  final String bvn;
  final String address;
  final String city;
  final String state;
  final bool hasGovernmentId;
  final bool hasSelfieWithId;
  final bool hasProofOfAddress;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Review Your Information'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyMedium(
            'Please review all information before submitting',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          _PersonalInfoSummary(
            fullName: '$firstName $lastName',
            dateOfBirth: dateOfBirth,
            gender: gender,
            nin: nin,
            bvn: bvn,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          _AddressSummary(
            address: address,
            city: city,
            state: state,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          _DocumentsSummary(
            hasGovernmentId: hasGovernmentId,
            hasSelfieWithId: hasSelfieWithId,
            hasProofOfAddress: hasProofOfAddress,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const InfoCard(
            title: 'Verification Process',
            content: VerificationConstants.verificationProcessInfo,
            color: AppColors.primary,
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoSummary extends StatelessWidget {
  const _PersonalInfoSummary({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.nin,
    required this.bvn,
  });

  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String nin;
  final String bvn;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.outlined,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Personal Information'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          ReviewRow(label: 'Full Name', value: fullName),
          ReviewRow(label: 'Date of Birth', value: dateOfBirth),
          ReviewRow(label: 'Gender', value: gender),
          ReviewRow(
            label: 'NIN',
            value: nin.isNotEmpty ? nin : 'Not provided',
          ),
          ReviewRow(
            label: 'BVN',
            value: bvn.isNotEmpty ? bvn : 'Not provided',
          ),
        ],
      ),
    );
  }
}

class _AddressSummary extends StatelessWidget {
  const _AddressSummary({
    required this.address,
    required this.city,
    required this.state,
  });

  final String address;
  final String city;
  final String state;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.outlined,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Address Information'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          ReviewRow(label: 'Address', value: address),
          ReviewRow(label: 'City', value: city),
          ReviewRow(label: 'State', value: state),
        ],
      ),
    );
  }
}

class _DocumentsSummary extends StatelessWidget {
  const _DocumentsSummary({
    required this.hasGovernmentId,
    required this.hasSelfieWithId,
    required this.hasProofOfAddress,
  });

  final bool hasGovernmentId;
  final bool hasSelfieWithId;
  final bool hasProofOfAddress;

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.outlined,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Uploaded Documents'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DocumentReviewRow(
            title: 'Government ID',
            isUploaded: hasGovernmentId,
          ),
          DocumentReviewRow(
            title: 'Selfie with ID',
            isUploaded: hasSelfieWithId,
          ),
          DocumentReviewRow(
            title: 'Proof of Address',
            isUploaded: hasProofOfAddress,
          ),
        ],
      ),
    );
  }
}
