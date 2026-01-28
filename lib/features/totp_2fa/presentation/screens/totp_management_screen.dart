import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../bloc/totp_cubit.dart';
import '../bloc/totp_data.dart';
import '../widgets/totp_management/new_recovery_codes_card.dart';
import '../widgets/totp_management/recovery_codes_section.dart';
import '../widgets/totp_management/totp_disable_section.dart';
import '../widgets/totp_management/totp_enable_section.dart';
import '../widgets/totp_management/totp_info_card.dart';
import '../widgets/totp_management/totp_status_card.dart';
import '../widgets/totp_verification_dialog.dart';

/// Screen for managing TOTP 2FA settings
class TotpManagementScreen extends StatefulWidget {
  const TotpManagementScreen({super.key});

  @override
  State<TotpManagementScreen> createState() => _TotpManagementScreenState();
}

class _TotpManagementScreenState extends State<TotpManagementScreen> {
  String get _userId => context.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TotpCubit>().loadSettings(_userId);
    });
  }

  Future<void> _enableTwoFactor() async {
    final result = await sl<NavigationService>().navigateTo(Routes.totp2FASetup);

    // GetX returns dynamic, so we need to check the result type
    if (result == true && mounted) {
      context.read<TotpCubit>().loadSettings(_userId);
    }
  }

  Future<void> _disableTwoFactor() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: AppText.titleLarge('Disable 2FA?', color: AppColors.onBackground),
        content: AppText.bodyMedium(
          'This will make your account less secure. You will need to verify your identity to disable 2FA.',
          color: AppColors.onSurfaceVariant,
        ),
        actions: [
          AppButton.text(
            onPressed: () => sl<NavigationService>().goBack<bool>(result: false),
            child: AppText.labelMedium('Cancel', color: AppColors.onSurface),
          ),
          AppButton.text(
            onPressed: () => sl<NavigationService>().goBack<bool>(result: true),
            child: AppText.labelMedium('Disable', color: AppColors.error),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final verified = await TotpVerificationDialog.show(
      context,
      userId: _userId,
      title: 'Verify to Disable 2FA',
      description: 'Enter your 2FA code to confirm',
    );

    if (verified && mounted) {
      context.read<TotpCubit>().disable2FA(_userId);
    }
  }

  Future<void> _regenerateRecoveryCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: AppText.titleLarge('Generate New Recovery Codes?', color: AppColors.onBackground),
        content: AppText.bodyMedium(
          'This will invalidate all existing recovery codes. Make sure to save the new codes.',
          color: AppColors.onSurfaceVariant,
        ),
        actions: [
          AppButton.text(
            onPressed: () => sl<NavigationService>().goBack<bool>(result: false),
            child: AppText.labelMedium('Cancel', color: AppColors.onSurface),
          ),
          AppButton.primary(
            onPressed: () => sl<NavigationService>().goBack<bool>(result: true),
            child: AppText.bodyMedium('Generate', color: AppColors.white),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final verified = await TotpVerificationDialog.show(
      context,
      userId: _userId,
      title: 'Verify Identity',
      description: 'Enter your 2FA code to generate new recovery codes',
    );

    if (verified && mounted) {
      context.read<TotpCubit>().regenerateRecoveryCodes(_userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: AppText.titleLarge('Two-Factor Authentication'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.onBackground,
      ),
      body: BlocManager<TotpCubit, BaseState<TotpData>>(
        bloc: context.read<TotpCubit>(),
        showLoadingIndicator: false,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(
                  state.successMessage ?? 'Success!',
                  color: AppColors.white,
                ),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.isError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(
                  state.errorMessage ?? 'An error occurred',
                  color: AppColors.white,
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final totpData = state.data ?? const TotpData();
          final isLoading = state.isLoading;

          if (isLoading && !totpData.isEnabled) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TotpCubit>().loadSettings(_userId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.paddingMD,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TotpInfoCard(),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  TotpStatusCard(
                    isEnabled: totpData.isEnabled,
                    isLoading: isLoading,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  if (totpData.isEnabled) ...[
                    RecoveryCodesSection(
                      remainingCodes: totpData.remainingRecoveryCodes,
                      isLoading: isLoading,
                      onRegenerate: _regenerateRecoveryCodes,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    TotpDisableSection(
                      isLoading: isLoading,
                      onDisable: _disableTwoFactor,
                    ),
                  ] else
                    TotpEnableSection(
                      isLoading: isLoading,
                      onEnable: _enableTwoFactor,
                    ),
                  if (totpData.hasRecoveryCodesToShow) ...[
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    NewRecoveryCodesCard(
                      recoveryCodes: totpData.setupResult?.recoveryCodes ?? [],
                      onAcknowledged: () {
                        context.read<TotpCubit>().hideRecoveryCodes();
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
