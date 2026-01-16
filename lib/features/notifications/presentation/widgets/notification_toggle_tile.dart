import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text.dart';

/// Reusable toggle tile for notification settings
class NotificationToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const NotificationToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (value ? AppColors.primary : AppColors.onSurfaceVariant)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 24,
          ),
        ),
        title: AppText.bodyLarge(
          title,
          fontWeight: FontWeight.w500,
        ),
        subtitle: AppText.bodySmall(
          subtitle,
          color: AppColors.textSecondary,
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
