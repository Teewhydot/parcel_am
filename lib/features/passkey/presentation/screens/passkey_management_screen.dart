import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../bloc/passkey_bloc.dart';
import '../bloc/passkey_data.dart';
import '../bloc/passkey_event.dart';
import '../widgets/passkey_management/add_passkey_button.dart';
import '../widgets/passkey_management/passkey_info_card.dart';
import '../widgets/passkey_management/passkey_not_supported_view.dart';
import '../widgets/passkey_management/passkeys_list.dart';

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
      body: BlocManager<PasskeyBloc, BaseState<PasskeyData>>(
        bloc: context.read<PasskeyBloc>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: false,
        child: const SizedBox.shrink(),
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.successMessage ?? 'Success!', color: AppColors.white),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.isError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.errorMessage ?? 'An error occurred', color: AppColors.white),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final passkeyData = state.data ?? const PasskeyData();

          if (!passkeyData.isSupported) {
            return const PasskeyNotSupportedView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PasskeyBloc>().add(const PasskeyListRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PasskeyInfoCard(),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  PasskeysList(
                    passkeyData: passkeyData,
                    isLoading: state.isLoading,
                    onRemove: (passkey) {
                      context.read<PasskeyBloc>().add(
                            PasskeyRemoveRequested(credentialId: passkey.credentialId),
                          );
                    },
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AddPasskeyButton(
                    isLoading: state.isLoading,
                    onPressed: () {
                      context.read<PasskeyBloc>().add(const PasskeyAppendRequested());
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
