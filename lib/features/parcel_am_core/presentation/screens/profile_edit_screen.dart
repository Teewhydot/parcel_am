import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/services/file_upload_service.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/features/parcel_am_core/data/models/user_model.dart';
import 'package:parcel_am/injection_container.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_data.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../features/file_upload/domain/use_cases/file_upload_usecase.dart';

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
    final authState = context.read<AuthBloc>().state;
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
    return BlocManager<AuthBloc, BaseState<AuthData>>(
      bloc: context.read<AuthBloc>(),
      listener: (context, state) {
        // Only navigate on SuccessState, not LoadedState
        if (state is LoadedState<AuthData>) {
          sl<NavigationService>().goBack();
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
                _buildImagePicker(),
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
                        onPressed: () {
                          // Validate form before proceeding
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          // Safety check: ensure context is still mounted
                          if (!mounted) {
                            return;
                          }

                          try {
                            final authBloc = context.read<AuthBloc>();

                            // Safety check: ensure bloc is not closed
                            if (authBloc.isClosed) {
                              if (mounted) {
                                context.showSnackbar(
                                  message: 'Session expired. Please refresh the app.',
                                  color: AppColors.error,
                                );
                              }
                              return;
                            }

                            authBloc.add(
                              AuthUserProfileUpdateRequested(
                                displayName: _displayNameController.text,
                              ),
                            );
                          } catch (e) {
                            if (mounted) {
                              context.showSnackbar(
                                message: 'Error: ${e.toString()}',
                                color: AppColors.error,
                              );
                            }
                          }
                        },
                        child: AppText.labelMedium(
                          'Save Changes',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.xxl),
                AppContainer(
                  padding: AppSpacing.paddingMD,
                  variant: ContainerVariant.outlined,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'Account',
                        variant: TextVariant.titleSmall,
                        fontWeight: FontWeight.w600,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      AppText.bodySmall(
                        'Signout from your account',
                        color: AppColors.onSurfaceVariant,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.outline(
                          key: const Key('signoutButton'),
                          onPressed: _handleSignout,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout,
                                size: 18,
                                color: AppColors.error,
                              ),
                              AppSpacing.horizontalSpacing(SpacingSize.xs),
                              AppText.labelMedium(
                                'Sign Out',
                                color: AppColors.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final fileUploadService = FileUploadService();
    final fileUploadUseCase = FileUploadUseCase();
    final userId = context.currentUserId;

    return Column(
      children: [
        StreamBuilder<Either<Failure, UserModel>>(
          stream: userId != null
              ? context.read<AuthBloc>().watchUserData(userId)
              : const Stream.empty(),
          builder: (context, asyncSnapshot) {
            String? profileImageUrl;

            if (asyncSnapshot.hasData) {
              asyncSnapshot.data!.fold(
                (failure) {
                  // Handle failure if needed
                },
                (userModel) {
                  profileImageUrl = userModel.profilePhotoUrl;
                },
              );
            }

            Widget imageWidget;
            if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
              imageWidget = CircleAvatar(
                radius: 50,
                backgroundImage: CachedNetworkImageProvider(profileImageUrl!),
              );
            } else if (asyncSnapshot.connectionState ==
                ConnectionState.waiting) {
              imageWidget = const CircularProgressIndicator.adaptive();
            } else {
              imageWidget = const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              );
            }

            return imageWidget;
          },
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        TextButton(
          key: const Key('changePhotoButton'),
          onPressed: () {
            final result = fileUploadService.pickImageFromGallery(
              allowMultiple: false,
            );
            result.then((file) async {
              if (context.mounted) {
                await fileUploadUseCase.uploadFile(
                  userId: context.currentUserId!,
                  file: file!,
                  folder: 'profile_images',
                );
              }
            });
          },
          child: AppText.bodySmall('Change Photo', color: AppColors.primary),
        ),
      ],
    );
  }

  Future<void> _handleSignout() async {
    final confirmed = await _showSignoutConfirmationDialog();

    if (confirmed == true) {
      final authBloc = context.read<AuthBloc>();
      authBloc.add(const AuthLogoutRequested());
    }
  }

  Future<bool?> _showSignoutConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: AppText.titleMedium('Sign Out'),
          content: AppText.bodyMedium(
            'Are you sure you want to sign out of your account?',
          ),
          actions: [
            AppButton.text(
              key: const Key('cancelSignoutButton'),
              onPressed: () => Navigator.of(context).pop(false),
              child: AppText.labelMedium('Cancel', color: AppColors.onSurface),
            ),
            AppButton.primary(
              key: const Key('confirmSignoutButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: AppText.labelMedium('Sign Out', color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}
