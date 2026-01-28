import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_text.dart';

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isEnabled ? 0.1 : 0.05),
          borderRadius: AppRadius.sm,
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: AppText.bodyLarge(
        title,
        fontWeight: FontWeight.w500,
        color: isEnabled ? null : AppColors.textSecondary,
      ),
      subtitle: AppText.bodySmall(
        subtitle,
        color: AppColors.textSecondary,
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      onTap: isEnabled ? () => onChanged!(!value) : null,
    );
  }
}
