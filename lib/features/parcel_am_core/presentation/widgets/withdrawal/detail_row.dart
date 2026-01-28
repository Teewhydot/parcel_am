import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          label,
          color: AppColors.onSurfaceVariant,
        ),
        Flexible(
          child: AppText.bodyMedium(
            value,
            textAlign: TextAlign.right,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DetailRowWithCopy extends StatelessWidget {
  const DetailRowWithCopy({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(
          '$label copied to clipboard',
          color: AppColors.white,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          label,
          color: AppColors.onSurfaceVariant,
        ),
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: AppText(
                  value,
                  textAlign: TextAlign.right,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CopyableDetailRow extends StatelessWidget {
  const CopyableDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(
          '$label copied to clipboard',
          color: AppColors.white,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          label,
          color: AppColors.onSurfaceVariant,
        ),
        AppSpacing.horizontalSpacing(SpacingSize.lg),
        Flexible(
          child: GestureDetector(
            onTap: () => _copyToClipboard(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText.bodyMedium(
                    value,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    textAlign: TextAlign.right,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.xs),
                const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
