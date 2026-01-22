import 'package:flutter/material.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  bool _chatNotificationsEnabled = true;
  bool _parcelUpdatesEnabled = true;
  bool _promotionalNotificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsToggleTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications on this device',
                value: _pushNotificationsEnabled,
                onChanged: (value) {
                  setState(() => _pushNotificationsEnabled = value);
                },
              ),
              _SettingsToggleTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Receive notifications via email',
                value: _emailNotificationsEnabled,
                onChanged: (value) {
                  setState(() => _emailNotificationsEnabled = value);
                },
              ),
              _SettingsToggleTile(
                icon: Icons.sms_outlined,
                title: 'SMS Notifications',
                subtitle: 'Receive notifications via SMS',
                value: _smsNotificationsEnabled,
                onChanged: (value) {
                  setState(() => _smsNotificationsEnabled = value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Notification Preferences',
            children: [
              _SettingsToggleTile(
                icon: Icons.chat_bubble_outline,
                title: 'Chat Messages',
                subtitle: 'Get notified about new messages',
                value: _chatNotificationsEnabled,
                onChanged: _pushNotificationsEnabled
                    ? (value) {
                        setState(() => _chatNotificationsEnabled = value);
                      }
                    : null,
              ),
              _SettingsToggleTile(
                icon: Icons.local_shipping_outlined,
                title: 'Parcel Updates',
                subtitle: 'Get notified about parcel status changes',
                value: _parcelUpdatesEnabled,
                onChanged: _pushNotificationsEnabled
                    ? (value) {
                        setState(() => _parcelUpdatesEnabled = value);
                      }
                    : null,
              ),
              _SettingsToggleTile(
                icon: Icons.campaign_outlined,
                title: 'Promotions & Offers',
                subtitle: 'Receive promotional messages and special offers',
                value: _promotionalNotificationsEnabled,
                onChanged: _pushNotificationsEnabled
                    ? (value) {
                        setState(() => _promotionalNotificationsEnabled = value);
                      }
                    : null,
              ),
            ],
          ),
          _SettingsSection(
            title: 'Security',
            children: [
              _SettingsTile(
                icon: Icons.fingerprint,
                title: 'Passkeys',
                subtitle: 'Manage your passkeys for passwordless login',
                onTap: () {
                  sl<NavigationService>().navigateTo(Routes.passkeyManagement);
                },
              ),
              _SettingsTile(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security with authenticator app',
                onTap: () {
                  sl<NavigationService>().navigateTo(Routes.totp2FAManagement);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AppText(
            title,
            variant: TextVariant.bodyMedium,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: AppRadius.sm,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
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
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleTile({
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
          color: AppColors.primary.withOpacity(isEnabled ? 0.1 : 0.05),
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
