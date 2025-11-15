import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';

class UserStatsGrid extends StatelessWidget {
  const UserStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, authState) {
        final user = authState is LoadedState<AuthData> ? authState.data?.user : null;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: UserStatCard(
                    title: 'Packages Sent',
                    value: '${user?.packagesSent ?? 12}',
                    icon: Icons.send,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: UserStatCard(
                    title: 'Packages Carried',
                    value: '${user?.completedDeliveries ?? 8}',
                    icon: Icons.luggage,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            Row(
              children: [
                Expanded(
                  child: UserStatCard(
                    title: 'Total Earned',
                    value: '₦${user?.totalEarnings?.toInt() ?? 45000}',
                    icon: Icons.monetization_on,
                    color: AppColors.accent,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: UserStatCard(
                    title: 'Rating',
                    value: '${user?.rating ?? 4.8}',
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
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodySmall(
            title,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}