import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_data.dart';

class UserStatsGrid extends StatelessWidget {
  const UserStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, BaseState<DashboardData>>(
      builder: (context, state) {
        final metrics = state.data?.metrics;
        final isLoading = state is LoadingState<DashboardData> ||
            state is AsyncLoadingState<DashboardData>;
        final hasData = metrics != null;

        final totalPackagesValue = hasData
            ? metrics.totalPackages.toString()
            : _placeholderValue(isLoading);
        final totalEarningsValue = hasData
            ? _formatCurrency(metrics.totalEarnings, metrics.currency)
            : _placeholderValue(isLoading);
        final successRateValue = hasData
            ? _formatSuccessRate(metrics.successRatePercent)
            : _placeholderValue(isLoading);
        final averageDeliveryValue = hasData
            ? _formatAverageDelivery(metrics.averageDeliveryTime, isLoading)
            : _placeholderValue(isLoading);

        final grid = Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: UserStatCard(
                    title: 'Total Packages',
                    value: totalPackagesValue,
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: UserStatCard(
                    title: 'Total Earnings',
                    value: totalEarningsValue,
                    icon: Icons.payments_outlined,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            Row(
              children: [
                Expanded(
                  child: UserStatCard(
                    title: 'Success Rate',
                    value: successRateValue,
                    icon: Icons.assessment_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: UserStatCard(
                    title: 'Avg Delivery Time',
                    value: averageDeliveryValue,
                    icon: Icons.timer_outlined,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ],
        );

        if (state is ErrorState<DashboardData> ||
            state is AsyncErrorState<DashboardData>) {
          final message = state is ErrorState<DashboardData>
              ? state.errorMessage
              : (state as AsyncErrorState<DashboardData>).errorMessage;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              grid,
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.bodySmall(
                message,
                color: AppColors.error,
              ),
            ],
          );
        }

        return grid;
      },
    );
  }

  String _placeholderValue(bool isLoading) => isLoading ? '...' : '--';

  String _formatCurrency(double value, String currency) {
    try {
      final symbol = NumberFormat.simpleCurrency(name: currency).currencySymbol;
      return NumberFormat.compactCurrency(
        symbol: symbol,
        decimalDigits: 0,
      ).format(value);
    } catch (_) {
      return NumberFormat.compactCurrency(
        symbol: '',
        decimalDigits: 0,
      ).format(value);
    }
  }

  String _formatSuccessRate(double percent) {
    return '${percent.clamp(0, 100).toStringAsFixed(0)}%';
  }

  String _formatAverageDelivery(Duration? duration, bool isLoading) {
    if (duration == null) {
      return _placeholderValue(isLoading);
    }

    if (duration.inDays >= 1) {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return '${days}d';
    }

    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }

    final minutes = duration.inMinutes;
    if (minutes >= 1) {
      return '${minutes}m';
    }

    final seconds = duration.inSeconds;
    if (seconds >= 1) {
      return '${seconds}s';
    }

    return '<1s';
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