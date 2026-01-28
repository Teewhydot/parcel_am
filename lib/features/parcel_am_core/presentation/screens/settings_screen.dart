import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../injection_container.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_tile.dart';
import '../widgets/settings/settings_toggle_tile.dart';
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
  String? get _userId => context.currentUserId;

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
      body: BlocManager<NotificationSettingsBloc, BaseState<NotificationSettingsData>>(
        bloc: context.read<NotificationSettingsBloc>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: false,
        child: const SizedBox.shrink(),
        builder: (context, state) {
          // Get current settings or defaults
          final settings = state.data?.settings ??
              NotificationSettingsEntity.defaultSettings();

          final isLoading = state is LoadingState<NotificationSettingsData> ||
              state is AsyncLoadingState<NotificationSettingsData>;

          return ListView(
            children: [
              SettingsSection(
                title: 'Notification Preferences',
                children: [
                  SettingsToggleTile(
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
                  SettingsToggleTile(
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
                  SettingsToggleTile(
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
                  SettingsToggleTile(
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
              SettingsSection(
                title: 'Security',
                children: [
                  SettingsTile(
                    icon: Icons.fingerprint,
                    title: 'Passkeys',
                    subtitle: 'Manage your passkeys for passwordless login',
                    onTap: () {
                      sl<NavigationService>().navigateTo(Routes.passkeyManagement);
                    },
                  ),
                  SettingsTile(
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

