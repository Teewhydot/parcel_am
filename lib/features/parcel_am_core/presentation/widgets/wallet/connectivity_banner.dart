import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    required this.isOnline,
  });

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: AppColors.warningDark),
          AppSpacing.horizontalSpacing(SpacingSize.sm),
          Expanded(
            child: AppText.bodyMedium(
              'No internet connection. Wallet operations are disabled.',
              color: AppColors.warningDark,
            ),
          ),
        ],
      ),
    );
  }
}
