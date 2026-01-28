import 'package:flutter/material.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';

class ParcelEmptyState extends StatelessWidget {
  const ParcelEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText(
            'No parcels yet',
            variant: TextVariant.titleLarge,
            fontSize: AppFontSize.xxl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Create your first parcel to get started',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppButton.primary(
            onPressed: () {
              sl<NavigationService>().navigateTo(Routes.createParcel);
            },
            leadingIcon: const Icon(Icons.add, color: AppColors.white),
            child: AppText.bodyMedium('Create Parcel', color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
