import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../widgets/profile_edit/profile_image_picker.dart';
import '../widgets/profile_edit/account_section.dart';
import '../widgets/profile_edit/signout_confirmation_dialog.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final authState = context.read<AuthCubit>().state;
    if (authState.data?.user != null) {
      final user = authState.data!.user!;
      _displayNameController.text = user.displayName;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      bloc: context.read<AuthCubit>(),
      listener: (context, state) {
        if (state is LoadedState<AuthData>) {
          sl<NavigationService>().goBack();
        }
        if (state is SuccessState) {
          sl<NavigationService>().navigateTo(Routes.login);
        }
      },
      child: AppScaffold(
        title: 'Edit Profile',
        appBarBackgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: AppSpacing.paddingXL,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ProfileImagePicker(),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                AppInput(
                  key: const Key('displayNameField'),
                  controller: _displayNameController,
                  label: 'Display Name',
                  hintText: 'Enter your display name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Display name is required';
                    }
                    if (value.length < 3) {
                      return 'Display name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppInput(
                  key: const Key('emailField'),
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                AppSpacing.verticalSpacing(SpacingSize.xl),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppButton.primary(
                        key: const Key('saveButton'),
                        onPressed: _handleSave,
                        child: AppText.labelMedium(
                          'Save Changes',
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.xxl),
                AccountSection(onSignout: _handleSignout),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final authBloc = context.read<AuthCubit>();

      if (authBloc.isClosed) {
        if (mounted) {
          context.showSnackbar(
            message: 'Session expired. Please refresh the app.',
            color: AppColors.error,
          );
        }
        return;
      }

      authBloc.updateUserProfile(_displayNameController.text);
    } catch (e) {
      if (mounted) {
        context.showSnackbar(
          message: 'Error: ${e.toString()}',
          color: AppColors.error,
        );
      }
    }
  }

  Future<void> _handleSignout() async {
    final confirmed = await SignoutConfirmationDialog.show(context);

    if (confirmed == true && mounted) {
      context.read<AuthCubit>().logout();
    }
  }
}
