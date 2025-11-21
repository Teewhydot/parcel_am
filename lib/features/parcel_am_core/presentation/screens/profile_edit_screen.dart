import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/routes/routes.dart';
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
  final ImagePicker _picker = ImagePicker();
  final _fileUploadUseCase = GetIt.instance<FileUploadUseCase>();

  XFile? _selectedImage;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is DataState<AuthData> && authState.data?.user != null) {
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
    return BlocListener<AuthBloc, BaseState<AuthData>>(
      listener: (context, state) {
        if (state is LoadingState) {
          setState(() => _isSubmitting = true);
        } else if (state is SuccessState) {
          setState(() => _isSubmitting = false);
          _showSuccessMessage(state.successMessage ?? 'Profile updated successfully');
        } else if (state is ErrorState) {
          setState(() => _isSubmitting = false);
          _showErrorMessage(state.errorMessage ?? 'Failed to update profile');
        } else if (state is LoadedState) {
          setState(() => _isSubmitting = false);
        } else if (state is InitialState) {
          // User has been logged out, navigate to login screen
          setState(() => _isSubmitting = false);
          Get.offAllNamed(Routes.login);
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
                      child: AppButton.outline(
                        key: const Key('cancelButton'),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: AppText.labelMedium('Cancel'),
                      ),
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      flex: 2,
                      child: AppButton.primary(
                        key: const Key('saveButton'),
                        onPressed: _isSubmitting ? null : _handleSave,
                        loading: _isSubmitting,
                        child: AppText.labelMedium(
                          _isUploadingImage
                              ? 'Uploading Image...'
                              : 'Save Changes',
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
                          onPressed: _isSubmitting ? null : _handleSignout,
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
    return Column(
      children: [
        GestureDetector(
          key: const Key('imagePickerButton'),
          onTap: _isSubmitting ? null : _pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: _selectedImage != null
                ? FileImage(File(_selectedImage!.path))
                : null,
            child: _selectedImage == null
                ? const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: AppColors.primary,
                  )
                : null,
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        TextButton(
          key: const Key('changePhotoButton'),
          onPressed: _isSubmitting ? null : _pickImage,
          child: AppText.bodySmall(
            'Change Photo',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;

      // Get current user ID
      String? userId;
      if (authState is DataState<AuthData> && authState.data?.user != null) {
        userId = authState.data!.user!.uid;
      }

      if (userId == null) {
        _showErrorMessage('User not found');
        return;
      }

      String? profileImageUrl;

      // Upload profile image if selected
      if (_selectedImage != null) {
        setState(() {
          _isUploadingImage = true;
          _isSubmitting = true;
        });

        try {
          final file = File(_selectedImage!.path);
          final result = await _fileUploadUseCase.uploadFile(
            userId: userId,
            file: file,
            folder: 'profile_images',
          );

          result.fold(
            (failure) {
              setState(() {
                _isUploadingImage = false;
                _isSubmitting = false;
              });
              _showErrorMessage(failure.failureMessage);
              return;
            },
            (uploadedFile) {
              profileImageUrl = uploadedFile.url;
              setState(() => _isUploadingImage = false);
            },
          );
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
            _isSubmitting = false;
          });
          _showErrorMessage('Failed to upload image: $e');
          return;
        }
      }

      // Update profile
      final authBloc = context.read<AuthBloc>();
      authBloc.add(AuthUserProfileUpdateRequested(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        additionalData: profileImageUrl != null
            ? {'profileImageUrl': profileImageUrl}
            : null,
      ));
    }
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
              child: AppText.labelMedium(
                'Cancel',
                color: AppColors.onSurface,
              ),
            ),
            AppButton.primary(
              key: const Key('confirmSignoutButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: AppText.labelMedium(
                'Sign Out',
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('successSnackBar'),
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('errorSnackBar'),
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
