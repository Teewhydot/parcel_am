import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../bloc/notification_settings_bloc.dart';
import '../bloc/notification_settings_event.dart';
import '../bloc/notification_settings_state.dart';
import '../widgets/notification_toggle_tile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const NotificationSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<NotificationSettingsBloc>()
        .add(LoadNotificationSettings(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Notification Settings'),
        actions: [
          BlocBuilder<NotificationSettingsBloc, BaseState<NotificationSettingsData>>(
            builder: (context, state) {
              final hasChanges = state.data?.hasChanges ?? false;
              return TextButton(
                onPressed: hasChanges
                    ? () {
                        context
                            .read<NotificationSettingsBloc>()
                            .add(SaveNotificationSettings(widget.userId));
                      }
                    : null,
                child: AppText.bodyMedium(
                  'Save',
                  color: hasChanges ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocManager<NotificationSettingsBloc, BaseState<NotificationSettingsData>>(
        bloc: context.read<NotificationSettingsBloc>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: true,
        showResultSuccessNotifications: true,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError && !state.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppText.bodyMedium(state.errorMessage ?? 'An error occurred'),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppButton.primary(
                    onPressed: () {
                      context
                          .read<NotificationSettingsBloc>()
                          .add(LoadNotificationSettings(widget.userId));
                    },
                    child: AppText.bodyMedium('Retry', color: AppColors.white),
                  ),
                ],
              ),
            );
          }

          if (state.hasData && state.data != null) {
            final settings = state.data!.settings;
            final isLoading = state is AsyncLoadingState;

            return Stack(
              children: [
                ListView(
                  children: [
                    // Messages Section
                    _buildSectionHeader('Messages'),
                    NotificationToggleTile(
                      title: 'Chat Messages',
                      subtitle: 'Notifications when you receive new messages',
                      icon: Icons.chat_bubble_outline,
                      value: settings.chatMessages,
                      enabled: !isLoading,
                      onChanged: (value) {
                        context.read<NotificationSettingsBloc>().add(
                              ToggleNotificationSetting(
                                settingKey: 'chatMessages',
                                value: value,
                              ),
                            );
                      },
                    ),
                    const Divider(height: 1),

                    // Parcels Section
                    _buildSectionHeader('Parcels'),
                    NotificationToggleTile(
                      title: 'Parcel Updates',
                      subtitle: 'Updates on your parcel requests and deliveries',
                      icon: Icons.local_shipping_outlined,
                      value: settings.parcelUpdates,
                      enabled: !isLoading,
                      onChanged: (value) {
                        context.read<NotificationSettingsBloc>().add(
                              ToggleNotificationSetting(
                                settingKey: 'parcelUpdates',
                                value: value,
                              ),
                            );
                      },
                    ),
                    const Divider(height: 1),
                    NotificationToggleTile(
                      title: 'Escrow Alerts',
                      subtitle: 'Payment hold, release, and dispute notifications',
                      icon: Icons.account_balance_wallet_outlined,
                      value: settings.escrowAlerts,
                      enabled: !isLoading,
                      onChanged: (value) {
                        context.read<NotificationSettingsBloc>().add(
                              ToggleNotificationSetting(
                                settingKey: 'escrowAlerts',
                                value: value,
                              ),
                            );
                      },
                    ),
                    const Divider(height: 1),

                    // App Section
                    _buildSectionHeader('App'),
                    NotificationToggleTile(
                      title: 'System Announcements',
                      subtitle: 'Important updates and news from the app',
                      icon: Icons.campaign_outlined,
                      value: settings.systemAnnouncements,
                      enabled: !isLoading,
                      onChanged: (value) {
                        context.read<NotificationSettingsBloc>().add(
                              ToggleNotificationSetting(
                                settingKey: 'systemAnnouncements',
                                value: value,
                              ),
                            );
                      },
                    ),
                    const Divider(height: 1),

                    // Reset to defaults
                    AppSpacing.verticalSpacing(SpacingSize.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppButton.outline(
                        onPressed: isLoading
                            ? null
                            : () {
                                context
                                    .read<NotificationSettingsBloc>()
                                    .add(const ResetNotificationSettings());
                              },
                        child: AppText.bodyMedium(
                          'Reset to Defaults',
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xl),

                    // Info text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppText.bodySmall(
                        'Note: You can always change these settings later. '
                        'Disabling notifications may cause you to miss important updates.',
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xl),
                  ],
                ),
                if (isLoading)
                  Container(
                    color: AppColors.surface.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
        child: Container(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: AppText.bodySmall(
        title.toUpperCase(),
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
