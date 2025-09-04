import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/verification_model.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final List<VerificationStep> steps;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      padding: AppSpacing.paddingXL,
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = index <= currentStep;
              final isCompleted = index < currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    AppContainer(
                      width: 32,
                      height: 32,
                      variant: ContainerVariant.filled,
                      color: isActive 
                          ? AppColors.primary 
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      alignment: Alignment.center,
                      child: Icon(
                        isCompleted ? Icons.check : steps[index].icon,
                        size: 16,
                        color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: AppContainer(
                          height: 2,
                          variant: ContainerVariant.filled,
                          color: index < currentStep 
                              ? AppColors.primary 
                              : AppColors.surfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          AppSpacing.verticalMD,
          AppText.titleMedium(
            steps[currentStep].title,
            fontWeight: FontWeight.w600,
          ),
          AppText.bodySmall(
            steps[currentStep].description,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class DocumentUploadCard extends StatefulWidget {
  final String title;
  final String description;
  final String documentKey;
  final DocumentUpload? uploadedDocument;
  final Function(DocumentUpload) onUpload;
  final bool isCamera;

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.description,
    required this.documentKey,
    this.uploadedDocument,
    required this.onUpload,
    this.isCamera = false,
  });

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickDocument() async {
    try {
      setState(() => _isUploading = true);
      
      final XFile? pickedFile = await _picker.pickImage(
        source: widget.isCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        
        // Create DocumentUpload object
        final document = DocumentUpload(
          fileName: pickedFile.name,
          filePath: pickedFile.path,
          uploadedAt: DateTime.now(),
          status: 'uploaded',
        );
        
        widget.onUpload(document);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = widget.uploadedDocument != null;
    
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleMedium(
                      widget.title,
                      fontWeight: FontWeight.w600,
                    ),
                    AppSpacing.verticalXS,
                    AppText.bodySmall(
                      widget.description,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              if (isUploaded)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 24,
                ),
            ],
          ),
          AppSpacing.verticalMD,
          if (!isUploaded)
            AppButton.outline(
              onPressed: _isUploading ? null : _pickDocument,
              child: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isCamera ? Icons.camera_alt : Icons.upload_file,
                          size: 16,
                        ),
                        AppSpacing.horizontalXS,
                        AppText.labelMedium(
                          widget.isCamera ? 'Take Photo' : 'Upload File',
                        ),
                      ],
                    ),
            )
          else
            AppContainer(
              padding: AppSpacing.paddingSM,
              variant: ContainerVariant.filled,
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  AppSpacing.horizontalXS,
                  Expanded(
                    child: AppText.bodySmall(
                      'Document uploaded successfully',
                      color: AppColors.success,
                    ),
                  ),
                  AppButton.text(
                    onPressed: _pickDocument,
                    child: AppText.labelSmall(
                      'Change',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final IconData icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.filled,
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      padding: AppSpacing.paddingMD,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          AppSpacing.horizontalSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: TextVariant.titleSmall,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                AppSpacing.verticalXS,
                AppText.bodySmall(
                  content,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TipsCard extends StatelessWidget {
  final String title;
  final List<String> tips;
  final Color color;
  final IconData icon;

  const TipsCard({
    super.key,
    required this.title,
    required this.tips,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      variant: ContainerVariant.filled,
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              AppSpacing.horizontalSM,
              AppText(
                title,
                variant: TextVariant.titleSmall,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          AppSpacing.verticalSM,
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  '• ',
                  color: AppColors.onSurfaceVariant,
                ),
                Expanded(
                  child: AppText.bodySmall(
                    tip,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const ReviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: AppText.bodySmall(
              label,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: AppText.bodyMedium(
              value.isNotEmpty ? value : 'Not provided',
              color: value.isNotEmpty ? null : AppColors.onSurfaceVariant,
              fontWeight: value.isNotEmpty ? FontWeight.w500 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentReviewRow extends StatelessWidget {
  final String title;
  final bool isUploaded;

  const DocumentReviewRow({
    super.key,
    required this.title,
    required this.isUploaded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.cancel,
            color: isUploaded ? AppColors.success : AppColors.error,
            size: 20,
          ),
          AppSpacing.horizontalSM,
          Expanded(
            child: AppText.bodyMedium(
              title,
              color: isUploaded ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}