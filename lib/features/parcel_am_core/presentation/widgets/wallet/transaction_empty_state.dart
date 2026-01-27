import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class TransactionEmptyState extends StatelessWidget {
  const TransactionEmptyState({
    super.key,
    required this.hasActiveFilters,
  });

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyLarge(
              hasActiveFilters
                  ? 'No transactions found'
                  : 'No transactions yet',
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
