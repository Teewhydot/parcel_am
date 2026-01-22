import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
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
import '../widgets/recovery_codes_widget.dart';
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
    final result = await sl<NavigationService>().navigateTo<bool>(Routes.totp2FASetup);

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
      body: BlocConsumer<TotpCubit, BaseState<TotpData>>(
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
                  _buildInfoCard(),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  _buildStatusCard(totpData, isLoading),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  if (totpData.isEnabled) ...[
                    _buildRecoveryCodesSection(totpData, isLoading),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    _buildDisableSection(isLoading),
                  ] else
                    _buildEnableSection(isLoading),
                  if (totpData.hasRecoveryCodesToShow) ...[
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    _buildNewRecoveryCodesCard(totpData),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'What is Two-Factor Authentication?',
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  '2FA adds an extra layer of security by requiring a code from your authenticator app in addition to your password.',
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(TotpData totpData, bool isLoading) {
    final isEnabled = totpData.isEnabled;

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled ? Icons.verified_user : Icons.shield_outlined,
              color: isEnabled ? AppColors.success : AppColors.warning,
              size: 24,
            ),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'Status',
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isEnabled ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.sm),
                    AppText.bodyMedium(
                      isEnabled ? 'Enabled' : 'Not Enabled',
                      color: isEnabled ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCodesSection(TotpData totpData, bool isLoading) {
    final remainingCodes = totpData.remainingRecoveryCodes;
    final isLow = remainingCodes <= 2;

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.key,
                color: isLow ? AppColors.warning : AppColors.onSurfaceVariant,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(
                      'Recovery Codes',
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xs),
                    AppText.bodyMedium(
                      '$remainingCodes codes remaining',
                      color: isLow ? AppColors.warning : AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLow) ...[
            AppSpacing.verticalSpacing(SpacingSize.md),
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Expanded(
                    child: AppText.bodySmall(
                      'You have few recovery codes left. Consider generating new ones.',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppButton.outline(
            onPressed: isLoading ? null : _regenerateRecoveryCodes,
            leadingIcon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
            child: AppText.bodyMedium('Generate New Codes', color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildNewRecoveryCodesCard(TotpData totpData) {
    final recoveryCodes = totpData.setupResult?.recoveryCodes ?? [];

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.bodyLarge(
            'New Recovery Codes',
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          RecoveryCodesWidget(
            recoveryCodes: recoveryCodes,
            onAcknowledged: () {
              context.read<TotpCubit>().hideRecoveryCodes();
            },
            isSetupMode: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEnableSection(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyLarge(
                'Protect Your Account',
                fontWeight: FontWeight.bold,
                color: AppColors.onBackground,
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              AppText.bodyMedium(
                'Enable 2FA to add an extra layer of security to sensitive actions like releasing escrow funds.',
                textAlign: TextAlign.center,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.lg),
        AppButton.primary(
          onPressed: isLoading ? null : _enableTwoFactor,
          fullWidth: true,
          leadingIcon: const Icon(Icons.add, color: AppColors.white, size: 20),
          child: AppText.bodyMedium('Enable 2FA', color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildDisableSection(bool isLoading) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.bodyLarge(
            'Disable 2FA',
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodyMedium(
            'This will make your account less secure. You will no longer need to verify for sensitive actions.',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppButton.outline(
            onPressed: isLoading ? null : _disableTwoFactor,
            child: AppText.bodyMedium('Disable 2FA', color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
