import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../data/providers/auth_provider.dart';

class UserStatsGrid extends StatelessWidget {
  const UserStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: UserStatCard(
                    title: 'Packages Sent',
                    value: '${authProvider.user?.packagesSent ?? 12}',
                    icon: Icons.send,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: UserStatCard(
                    title: 'Packages Carried',
                    value: '${authProvider.user?.completedDeliveries ?? 8}',
                    icon: Icons.luggage,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMD,
            Row(
              children: [
                Expanded(
                  child: UserStatCard(
                    title: 'Total Earned',
                    value: '₦${authProvider.user?.totalEarnings?.toInt() ?? 45000}',
                    icon: Icons.monetization_on,
                    color: AppColors.accent,
                  ),
                ),
                AppSpacing.horizontalMD,
                Expanded(
                  child: UserStatCard(
                    title: 'Rating',
                    value: '${authProvider.user?.rating ?? 4.8}',
                    icon: Icons.star,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class UserStatCard extends StatelessWidget {
  const UserStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppIcon.filled(
                icon: icon,
                size: IconSize.small,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
              ),
              AppText.titleLarge(
                value,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          AppSpacing.verticalSM,
          AppText.bodySmall(
            title,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}