import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/user_bank_account_entity.dart';
import '../../bloc/bank_account/bank_account_bloc.dart';
import '../../bloc/bank_account/bank_account_event.dart';

class BankAccountListCard extends StatelessWidget {
  const BankAccountListCard({
    super.key,
    required this.account,
    required this.isDefault,
    required this.userId,
  });

  final UserBankAccountEntity account;
  final bool isDefault;
  final String userId;

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleMedium('Delete Bank Account', fontWeight: FontWeight.w600),
        content: AppText.bodyMedium(
          'Are you sure you want to delete ${account.bankName} - ${account.maskedAccountNumber}?',
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.bodyMedium('Cancel', color: AppColors.primary),
          ),
          AppButton.text(
            onPressed: () => Navigator.pop(context, true),
            child: AppText.bodyMedium('Delete', color: AppColors.error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Dismissible(
        key: Key(account.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.sm,
          ),
          child: const Icon(
            Icons.delete,
            color: AppColors.white,
            size: 32,
          ),
        ),
        confirmDismiss: (direction) => _showDeleteConfirmation(context),
        onDismissed: (direction) {
          context.read<BankAccountBloc>().add(
                BankAccountDeleteRequested(
                  userId: userId,
                  accountId: account.id,
                ),
              );
        },
        child: ListTile(
          contentPadding: AppSpacing.paddingMD,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.account_balance,
              color: AppColors.primary,
            ),
          ),
          title: AppText.bodyLarge(
            account.accountName,
            fontWeight: FontWeight.w600,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodyMedium(
                account.bankName,
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodyMedium(
                account.maskedAccountNumber,
                color: AppColors.textSecondary,
              ),
              if (isDefault) ...[
                AppSpacing.verticalSpacing(SpacingSize.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadius.xs,
                  ),
                  child: AppText(
                    'DEFAULT',
                    variant: TextVariant.bodySmall,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successDark,
                  ),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final confirmed = await _showDeleteConfirmation(context);
              if (confirmed == true && context.mounted) {
                context.read<BankAccountBloc>().add(
                      BankAccountDeleteRequested(
                        userId: userId,
                        accountId: account.id,
                      ),
                    );
              }
            },
          ),
        ),
      ),
    );
  }
}
