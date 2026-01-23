import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../bloc/totp_cubit.dart';
import '../bloc/totp_data.dart';
import 'totp_code_input_widget.dart';

/// Dialog for TOTP 2FA verification
/// Used for protected actions like escrow release
class TotpVerificationDialog extends StatefulWidget {
  /// User ID for verification
  final String userId;

  /// Dialog title
  final String title;

  /// Description text
  final String description;

  const TotpVerificationDialog({
    super.key,
    required this.userId,
    this.title = 'Two-Factor Authentication',
    this.description = 'Enter the 6-digit code from your authenticator app',
  });

  /// Show the verification dialog and return true if verified successfully
  static Future<bool> show(
    BuildContext context, {
    required String userId,
    String title = 'Two-Factor Authentication',
    String description = 'Enter the 6-digit code from your authenticator app',
  }) async {
    // Clear any previous verification state before showing dialog
    context.read<TotpCubit>().clearVerification();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TotpVerificationDialog(
        userId: userId,
        title: title,
        description: description,
      ),
    );
    return result ?? false;
  }

  @override
  State<TotpVerificationDialog> createState() => _TotpVerificationDialogState();
}

class _TotpVerificationDialogState extends State<TotpVerificationDialog> {
  bool _useRecoveryCode = false;
  String? _errorMessage;
  final _recoveryCodeController = TextEditingController();

  @override
  void dispose() {
    _recoveryCodeController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String code) {
    setState(() {
      _errorMessage = null;
    });
  }

  void _onCodeCompleted(String code) {
    _verifyCode(code);
  }

  Future<void> _verifyCode(String code) async {
    if (code.isEmpty) return;

    final cubit = context.read<TotpCubit>();
    bool success;

    if (_useRecoveryCode) {
      success = await cubit.verifyWithRecoveryCode(widget.userId, code);
    } else {
      success = await cubit.verifyForAction(widget.userId, code);
    }

    if (success && mounted) {
      sl<NavigationService>().goBack<bool>(result: true);
    }
  }

  void _toggleRecoveryCode() {
    setState(() {
      _useRecoveryCode = !_useRecoveryCode;
      _errorMessage = null;
      _recoveryCodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TotpCubit, BaseState<TotpData>>(
      listener: (context, state) {
        if (state is ErrorState<TotpData>) {
          setState(() {
            _errorMessage = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is LoadingState;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
          title: Row(
            children: [
              const Icon(Icons.security, color: AppColors.primary),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppText.titleLarge(
                  widget.title,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText.bodyMedium(
                  _useRecoveryCode
                      ? 'Enter one of your recovery codes'
                      : widget.description,
                  color: AppColors.onSurfaceVariant,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xl),
                if (_useRecoveryCode)
                  _buildRecoveryCodeInput()
                else
                  TotpCodeInputWidget(
                    onChanged: _onCodeChanged,
                    onCompleted: _onCodeCompleted,
                    enabled: !isLoading,
                    errorMessage: _errorMessage,
                    autoFocus: true,
                  ),
                AppSpacing.verticalSpacing(SpacingSize.md),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: AppSpacing.paddingSM,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!isLoading)
                  AppButton.text(
                    onPressed: _toggleRecoveryCode,
                    child: AppText.labelMedium(
                      _useRecoveryCode
                          ? 'Use authenticator app instead'
                          : 'Use a recovery code instead',
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            AppButton.text(
              onPressed: isLoading ? null : () => sl<NavigationService>().goBack<bool>(result: false),
              child: AppText.labelMedium('Cancel', color: AppColors.onSurface),
            ),
            if (_useRecoveryCode)
              AppButton.primary(
                onPressed: isLoading || _recoveryCodeController.text.isEmpty
                    ? null
                    : () => _verifyCode(_recoveryCodeController.text),
                child: AppText.bodyMedium('Verify', color: AppColors.white),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecoveryCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          controller: _recoveryCodeController,
          hintText: 'XXXXXXXX-XXXXXXXX',
          errorText: _errorMessage,
          borderRadius: AppRadius.sm,
          onChanged: (value) {
            setState(() {
              _errorMessage = null;
            });
          },
          onSubmitted: _verifyCode,
        ),
        AppSpacing.verticalSpacing(SpacingSize.xs),
        AppText.bodySmall(
          'Recovery codes are single-use and cannot be reused',
          textAlign: TextAlign.center,
          color: AppColors.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// Helper function to show TOTP verification dialog
/// Returns true if verification was successful
Future<bool> showTotpVerificationDialog(
  BuildContext context, {
  required String userId,
  String title = 'Two-Factor Authentication',
  String description = 'Enter the 6-digit code from your authenticator app',
}) {
  return TotpVerificationDialog.show(
    context,
    userId: userId,
    title: title,
    description: description,
  );
}
