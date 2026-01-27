import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_input.dart';

class SelectPaymentStep extends StatelessWidget {
  const SelectPaymentStep({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.accountNumberController,
    required this.bankNameController,
  });

  final List<Map<String, dynamic>> paymentMethods;
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final TextEditingController accountNumberController;
  final TextEditingController bankNameController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Select Payment Method',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              for (var method in paymentMethods) ...[
                _PaymentMethodOption(
                  method: method,
                  isSelected: selectedPaymentMethod == method['id'],
                  onTap: () => onPaymentMethodChanged(method['id']),
                ),
              ],
            ],
          ),
        ),
        if (selectedPaymentMethod == 'bank') ...[
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'Bank Account Details',
                  fontWeight: FontWeight.bold,
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                AppInput(
                  controller: accountNumberController,
                  label: 'Account Number',
                  hintText: '0123456789',
                  keyboardType: TextInputType.number,
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                AppInput(
                  controller: bankNameController,
                  label: 'Bank Name',
                  hintText: 'Select your bank',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, dynamic> method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: SpacingSize.md.value),
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: 2,
          ),
          borderRadius: AppRadius.md,
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: method['id'],
              groupValue: isSelected ? method['id'] : null,
              onChanged: (_) => onTap(),
            ),
            Icon(
              method['icon'] as IconData,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
            AppSpacing.horizontalSpacing(SpacingSize.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(
                    method['name'],
                    fontWeight: FontWeight.w600,
                  ),
                  AppText.bodyMedium(
                    method['description'],
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            if (method['popular'] == true)
              Container(
                padding: AppSpacing.verticalPaddingXS + AppSpacing.horizontalPaddingSM,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.md,
                ),
                child: AppText.bodySmall(
                  'Popular',
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
