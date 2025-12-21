import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../bloc/passkey_bloc.dart';
import '../bloc/passkey_data.dart';
import '../bloc/passkey_event.dart';
import '../widgets/passkey_list_item.dart';

/// Screen for managing passkeys (add, view, remove)
class PasskeyManagementScreen extends StatefulWidget {
  const PasskeyManagementScreen({super.key});

  @override
  State<PasskeyManagementScreen> createState() => _PasskeyManagementScreenState();
}

class _PasskeyManagementScreenState extends State<PasskeyManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load passkeys when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PasskeyBloc>().add(const PasskeyCheckSupport());
      context.read<PasskeyBloc>().add(const PasskeyListRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: AppText.titleLarge('Passkey Authentication'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.onBackground,
      ),
      body: BlocConsumer<PasskeyBloc, BaseState<PasskeyData>>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.successMessage ?? 'Success!', color: Colors.white),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.isError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.errorMessage ?? 'An error occurred', color: Colors.white),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final passkeyData = state.data ?? const PasskeyData();

          if (!passkeyData.isSupported) {
            return _buildNotSupportedView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PasskeyBloc>().add(const PasskeyListRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  _buildPasskeysList(passkeyData, state.isLoading),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  _buildAddPasskeyButton(state.isLoading),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotSupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 40,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.lg),
            AppText(
              'Passkeys Not Supported',
              variant: TextVariant.titleLarge,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppText.bodyMedium(
              'Your device doesn\'t support passkey authentication. Please update your device or use password login.',
              textAlign: TextAlign.center,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 24,
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'What are Passkeys?',
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText(
                  'Passkeys replace passwords with secure biometric authentication. '
                  'Sign in with your fingerprint, face, or device screen lock.',
                  variant: TextVariant.bodySmall,
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasskeysList(PasskeyData passkeyData, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Your Passkeys',
              variant: TextVariant.titleMedium,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        if (passkeyData.passkeys.isEmpty && !isLoading)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: passkeyData.passkeys.length,
            itemBuilder: (context, index) {
              final passkey = passkeyData.passkeys[index];
              return PasskeyListItem(
                passkey: passkey,
                isLoading: isLoading,
                onRemove: () {
                  context.read<PasskeyBloc>().add(
                        PasskeyRemoveRequested(credentialId: passkey.credentialId),
                      );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outline,
          style: BorderStyle.solid,
        ),
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
              Icons.fingerprint,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyLarge(
            'No Passkeys Yet',
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Add a passkey to enable quick sign-in with your biometrics',
            textAlign: TextAlign.center,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildAddPasskeyButton(bool isLoading) {
    return AppButton.primary(
      onPressed: isLoading
          ? null
          : () {
              context.read<PasskeyBloc>().add(const PasskeyAppendRequested());
            },
      loading: isLoading,
      fullWidth: true,
      leadingIcon: const Icon(Icons.add, color: Colors.white, size: 20),
      child: AppText.bodyMedium('Add New Passkey', color: Colors.white),
    );
  }
}
