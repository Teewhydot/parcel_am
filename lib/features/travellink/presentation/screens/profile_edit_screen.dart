import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
  
  XFile? _selectedImage;
  bool _isSubmitting = false;

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
                          'Save Changes',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final authBloc = context.read<AuthBloc>();
      
      authBloc.add(AuthUserProfileUpdateRequested(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
      ));
    }
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
