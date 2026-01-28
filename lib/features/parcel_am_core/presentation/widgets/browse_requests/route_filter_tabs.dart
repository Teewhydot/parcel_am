import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';

class RouteFilterTabs extends StatelessWidget {
  const RouteFilterTabs({
    super.key,
    required this.routes,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> routes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: AppRadius.pill,
              ),
              child: AppText.bodyMedium(
                routes[index],
                color: isSelected ? AppColors.white : AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
