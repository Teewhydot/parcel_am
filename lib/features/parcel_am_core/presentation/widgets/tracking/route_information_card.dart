import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/package_entity.dart';

class RouteInformationCard extends StatelessWidget {
  const RouteInformationCard({super.key, required this.package});

  final PackageEntity package;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Route Information'),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.circle, size: 8, color: AppColors.white),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('From: ${package.origin.name}', variant: TextVariant.titleSmall),
                    AppText.bodySmall(package.origin.address, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Row(
            children: [
              AppSpacing.horizontalSpacing(SpacingSize.sm),
              Container(width: 2, height: 32, color: AppColors.outline),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, size: 12, color: AppColors.white),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('To: ${package.destination.name}', variant: TextVariant.titleSmall),
                    AppText.bodySmall(package.destination.address, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
