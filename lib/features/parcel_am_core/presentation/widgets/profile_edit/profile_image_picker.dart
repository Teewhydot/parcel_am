import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/helpers/user_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../file_upload/domain/use_cases/file_upload_usecase.dart';
import '../../../../file_upload/services/file_upload_service.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/auth/auth_cubit.dart';

class ProfileImagePicker extends StatelessWidget {
  const ProfileImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final fileUploadService = FileUploadService();
    final fileUploadUseCase = FileUploadUseCase();
    final userId = context.currentUserId;

    return Column(
      children: [
        StreamBuilder<Either<Failure, UserEntity>>(
          stream: userId != null
              ? context.read<AuthCubit>().watchUserData(userId)
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
        AppButton.text(
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
}
