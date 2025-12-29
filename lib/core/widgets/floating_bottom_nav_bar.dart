import 'package:flutter/material.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_font_size.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.xxl,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, -5),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            items.length,
            (index) => _buildNavItem(
              context,
              items[index],
              index,
              currentIndex == index,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    FloatingNavItem item,
    int index,
    bool isActive,
  ) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: AppRadius.lg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.transparent,
                      borderRadius: AppRadius.md,
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: AppText(
                            item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                            variant: TextVariant.bodySmall,
                            fontSize: AppFontSize.xs,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText(
                item.label,
                variant: TextVariant.bodySmall,
                fontSize: AppFontSize.sm,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const FloatingNavItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
    this.badgeCount,
  }) : activeIcon = activeIcon ?? icon;
}
