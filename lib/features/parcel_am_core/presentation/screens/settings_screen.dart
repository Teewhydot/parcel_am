import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../../../notifications/domain/entities/notification_settings_entity.dart';
import '../../../notifications/presentation/bloc/notification_settings_bloc.dart';
import '../../../notifications/presentation/bloc/notification_settings_event.dart';
import '../../../notifications/presentation/bloc/notification_settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    if (_userId != null) {
      context.read<NotificationSettingsBloc>().add(
            LoadNotificationSettings(_userId!),
          );
    }
  }

  void _toggleSetting(String settingKey, bool value) {
    if (_userId != null) {
      final bloc = context.read<NotificationSettingsBloc>();
      // Toggle the setting locally
      bloc.add(ToggleNotificationSetting(settingKey: settingKey, value: value));
      // Immediately persist to Firestore
      bloc.add(SaveNotificationSettings(_userId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      body: BlocBuilder<NotificationSettingsBloc, BaseState<NotificationSettingsData>>(
        builder: (context, state) {
          // Get current settings or defaults
          final settings = state.data?.settings ??
              NotificationSettingsEntity.defaultSettings();

          final isLoading = state is LoadingState<NotificationSettingsData> ||
              state is AsyncLoadingState<NotificationSettingsData>;

          return ListView(
            children: [
              _SettingsSection(
                title: 'Notification Preferences',
                children: [
                  _SettingsToggleTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat Messages',
                    subtitle: 'Get notified about new messages',
                    value: settings.chatMessages,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            _toggleSetting('chatMessages', value);
                          },
                  ),
                  _SettingsToggleTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Parcel Updates',
                    subtitle: 'Get notified about parcel status changes',
                    value: settings.parcelUpdates,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            _toggleSetting('parcelUpdates', value);
                          },
                  ),
                  _SettingsToggleTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Escrow & Payment Alerts',
                    subtitle: 'Get notified about payment updates',
                    value: settings.escrowAlerts,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            _toggleSetting('escrowAlerts', value);
                          },
                  ),
                  _SettingsToggleTile(
                    icon: Icons.campaign_outlined,
                    title: 'System Announcements',
                    subtitle: 'Receive system updates and announcements',
                    value: settings.systemAnnouncements,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            _toggleSetting('systemAnnouncements', value);
                          },
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
          );
        },
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
