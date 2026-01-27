import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../parcel_am_core/data/constants/verification_constants.dart';
import '../../../domain/models/verification_model.dart';
import '../verification_widgets.dart';

class IdentityVerificationStep extends StatelessWidget {
  const IdentityVerificationStep({
    super.key,
    required this.isGovernmentIdUploaded,
    required this.isSelfieWithIdUploaded,
    required this.onGovernmentIdUpload,
    required this.onSelfieWithIdUpload,
  });

  final bool isGovernmentIdUploaded;
  final bool isSelfieWithIdUploaded;
  final Future<void> Function(DocumentUpload) onGovernmentIdUpload;
  final Future<void> Function(DocumentUpload) onSelfieWithIdUpload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Upload Identity Documents'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyMedium(
            'Please upload clear, readable photos of your documents',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          DocumentUploadCard(
            title: 'Government ID',
            description:
                'Upload your NIN slip, Driver\'s License, or International Passport',
            documentKey: 'government_id',
            isUploaded: isGovernmentIdUploaded,
            onUpload: onGovernmentIdUpload,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DocumentUploadCard(
            title: 'Selfie with ID',
            description:
                'Upload a photo holding your government ID next to your face',
            documentKey: 'selfie_with_id',
            isUploaded: isSelfieWithIdUploaded,
            onUpload: onSelfieWithIdUpload,
            isCamera: false,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const TipsCard(
            title: 'Tips for better photos',
            tips: VerificationConstants.photoTips,
            color: AppColors.accent,
            icon: Icons.lightbulb_outline,
          ),
        ],
      ),
    );
  }
}
