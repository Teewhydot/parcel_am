import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class FundingStatusIcon extends StatelessWidget {
  const FundingStatusIcon({
    super.key,
    required this.isLoading,
    required this.isSuccess,
    required this.isPending,
    required this.scaleAnimation,
  });

  final bool isLoading;
  final bool isSuccess;
  final bool isPending;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    if (isSuccess) {
      return ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.successDark,
          ),
        ),
      );
    } else if (isPending) {
      return Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: AppColors.pendingLight,
          shape: BoxShape.circle,
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.pendingDark),
              ),
            ),
            Icon(
              Icons.hourglass_empty,
              size: 40,
              color: AppColors.pendingDark,
            ),
          ],
        ),
      );
    } else {
      return ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            size: 80,
            color: AppColors.errorDark,
          ),
        ),
      );
    }
  }
}
