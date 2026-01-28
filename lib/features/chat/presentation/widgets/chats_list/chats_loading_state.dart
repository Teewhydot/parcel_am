import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_spacing.dart';

/// Skeleton loading state for the chats list screen.
class ChatsLoadingState extends StatelessWidget {
  const ChatsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surface,
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.sm,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.sm,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.sm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
