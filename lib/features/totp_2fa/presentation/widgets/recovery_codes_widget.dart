import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';

/// Widget displaying recovery codes with copy and download options
class RecoveryCodesWidget extends StatelessWidget {
  /// List of recovery codes to display
  final List<String> recoveryCodes;

  /// Callback when user acknowledges they saved the codes
  final VoidCallback? onAcknowledged;

  /// Whether this is shown during initial setup
  final bool isSetupMode;

  const RecoveryCodesWidget({
    super.key,
    required this.recoveryCodes,
    this.onAcknowledged,
    this.isSetupMode = true,
  });

  void _copyAllCodes(BuildContext context) {
    final codesText = recoveryCodes.join('\n');
    Clipboard.setData(ClipboardData(text: codesText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(
          'Recovery codes copied to clipboard',
          color: AppColors.white,
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppRadius.sm,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppText.bodyMedium(
                  'Save these codes in a secure place. They will only be shown once!',
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        AppText.bodyMedium(
          'Use these codes to access your account if you lose your authenticator device. Each code can only be used once.',
          color: AppColors.onSurfaceVariant,
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: recoveryCodes.map((code) {
                  return SizedBox(
                    width: 140,
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        fontSize: 16,
                        color: AppColors.onBackground,
                      ),
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppButton.outline(
                onPressed: () => _copyAllCodes(context),
                leadingIcon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                child: AppText.bodyMedium('Copy all codes', color: AppColors.primary),
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        AppText.bodySmall(
          '${recoveryCodes.length} recovery codes remaining',
          textAlign: TextAlign.center,
          color: AppColors.onSurfaceVariant,
        ),
        if (isSetupMode && onAcknowledged != null) ...[
          AppSpacing.verticalSpacing(SpacingSize.xl),
          _AcknowledgmentSection(onAcknowledged: onAcknowledged!),
        ],
      ],
    );
  }
}

class _AcknowledgmentSection extends StatefulWidget {
  final VoidCallback onAcknowledged;

  const _AcknowledgmentSection({required this.onAcknowledged});

  @override
  State<_AcknowledgmentSection> createState() => _AcknowledgmentSectionState();
}

class _AcknowledgmentSectionState extends State<_AcknowledgmentSection> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          value: _acknowledged,
          onChanged: (value) {
            setState(() {
              _acknowledged = value ?? false;
            });
          },
          title: AppText.bodyMedium(
            'I have saved these recovery codes in a secure location',
            color: AppColors.onBackground,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        AppButton.primary(
          onPressed: _acknowledged ? widget.onAcknowledged : null,
          fullWidth: true,
          child: AppText.bodyMedium('Continue', color: AppColors.white),
        ),
      ],
    );
  }
}
