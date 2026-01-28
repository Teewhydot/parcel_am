import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../../services/authenticator_app_launcher.dart';
import '../bloc/totp_cubit.dart';
import '../bloc/totp_data.dart';
import '../widgets/totp_setup/qr_code_step.dart';
import '../widgets/totp_setup/recovery_codes_step.dart';
import '../widgets/totp_setup/setup_stepper.dart';
import '../widgets/totp_setup/verification_step.dart';

/// Screen for setting up TOTP 2FA
class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  int _currentStep = 0;
  bool _isAuthenticatorAppAvailable = false;
  bool _isLaunchingApp = false;
  bool _hasCheckedAppAvailability = false;

  final _authenticatorLauncher = AuthenticatorAppLauncher();

  String get _userId => context.currentUserId ?? '';
  String get _userEmail => context.user.email;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TotpCubit>().startSetup(_userId, _userEmail);
    });
  }

  Future<void> _checkAuthenticatorAppAvailability(String qrCodeUri) async {
    if (_hasCheckedAppAvailability) return;

    final canLaunch = await _authenticatorLauncher.canLaunchAuthenticatorApp(
      qrCodeUri,
    );

    if (mounted) {
      setState(() {
        _isAuthenticatorAppAvailable = canLaunch;
        _hasCheckedAppAvailability = true;
      });
    }
  }

  Future<void> _handleOpenInAuthenticatorApp(String qrCodeUri) async {
    setState(() {
      _isLaunchingApp = true;
    });

    final launched = await _authenticatorLauncher.launchAuthenticatorApp(
      qrCodeUri,
    );

    if (mounted) {
      setState(() {
        _isLaunchingApp = false;
      });

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText.bodyMedium(
              _authenticatorLauncher.getNoAppInstalledShortMessage(),
              color: AppColors.white,
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _onVerificationCodeCompleted(String code) {
    context.read<TotpCubit>().completeSetup(_userId, code);
  }

  void _onRecoveryCodesAcknowledged() {
    context.read<TotpCubit>().hideRecoveryCodes();
    sl<NavigationService>().goBack<bool>(result: true);
  }

  void _cancelSetup() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: AppText.titleLarge('Cancel Setup?', color: AppColors.onBackground),
        content: AppText.bodyMedium(
          'Are you sure you want to cancel 2FA setup? You will need to start over.',
          color: AppColors.onSurfaceVariant,
        ),
        actions: [
          AppButton.text(
            onPressed: () => sl<NavigationService>().goBack(),
            child: AppText.labelMedium('Continue Setup', color: AppColors.onSurface),
          ),
          AppButton.text(
            onPressed: () {
              sl<NavigationService>().goBack();
              context.read<TotpCubit>().cancelSetup(_userId);
              sl<NavigationService>().goBack<bool>(result: false);
            },
            child: AppText.labelMedium('Cancel', color: AppColors.error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancelSetup();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: AppText.titleLarge('Enable 2FA'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          foregroundColor: AppColors.onBackground,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelSetup,
          ),
        ),
        body: BlocManager<TotpCubit, BaseState<TotpData>>(
          bloc: context.read<TotpCubit>(),
          showLoadingIndicator: false,
          showResultErrorNotifications: false,
          listener: (context, state) {
            // Navigate to recovery codes step when 2FA is successfully enabled
            // Check for SuccessState OR LoadedState with isEnabled while in verification step
            if (state.isSuccess ||
                (_currentStep == 1 && state.data?.isEnabled == true)) {
              setState(() {
                _currentStep = 2;
              });
            } else if (state.isError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText.bodyMedium(
                    state.errorMessage ?? 'Verification failed',
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

            // Check authenticator app availability when setup result is available
            if (totpData.setupResult != null && !_hasCheckedAppAvailability) {
              _checkAuthenticatorAppAvailability(totpData.setupResult!.qrCodeUri);
            }

            if (isLoading && totpData.setupResult == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: AppSpacing.paddingMD,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SetupStepper(currentStep: _currentStep),
                  AppSpacing.verticalSpacing(SpacingSize.xl),
                  if (_currentStep == 0)
                    QrCodeStep(
                      totpData: totpData,
                      isLoading: isLoading,
                      isAuthenticatorAppAvailable: _isAuthenticatorAppAvailable,
                      isLaunchingApp: _isLaunchingApp,
                      onOpenInAuthenticatorApp: () =>
                          _handleOpenInAuthenticatorApp(
                              totpData.setupResult!.qrCodeUri),
                      onContinue: () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                    ),
                  if (_currentStep == 1)
                    VerificationStep(
                      totpData: totpData,
                      isLoading: isLoading,
                      onCodeCompleted: _onVerificationCodeCompleted,
                      onBack: () {
                        setState(() {
                          _currentStep = 0;
                        });
                      },
                    ),
                  if (_currentStep == 2)
                    RecoveryCodesStep(
                      totpData: totpData,
                      onAcknowledged: _onRecoveryCodesAcknowledged,
                    ),
                ],
              ),
            );
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

}
