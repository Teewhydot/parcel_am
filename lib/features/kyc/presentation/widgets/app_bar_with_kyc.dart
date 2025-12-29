import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_data.dart';
import 'kyc_status_widgets.dart';

/// AppBar with integrated KYC status indicator
class AppBarWithKyc extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showKycIndicator;
  final Widget? leading;
  final Color? backgroundColor;
  final double elevation;

  const AppBarWithKyc({
    super.key,
    required this.title,
    this.actions,
    this.showKycIndicator = true,
    this.leading,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AppText.titleLarge(title),
      leading: leading,
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: elevation,
      actions: [
        if (showKycIndicator) ...[
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: KycStatusIndicator()),
          ),
        ],
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Profile header widget with KYC status badge
class ProfileHeaderWithKyc extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final VoidCallback? onPhotoTap;

  const ProfileHeaderWithKyc({
    super.key,
    this.photoUrl,
    required this.displayName,
    required this.email,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        KycStatus status = KycStatus.notStarted;
        
        if (state is DataState<AuthData> && state.data?.user != null) {
          status = state.data!.user!.kycStatus;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: onPhotoTap,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: photoUrl != null 
                          ? NetworkImage(photoUrl!) 
                          : null,
                      child: photoUrl == null
                          ? AppText(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              variant: TextVariant.headlineMedium,
                              fontSize: AppFontSize.headlineLarge,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: KycStatusBadge(
                      status: status,
                      compact: true,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppText(
                displayName,
                variant: TextVariant.titleLarge,
                fontSize: AppFontSize.titleLarge,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText(
                email,
                variant: TextVariant.bodyMedium,
                fontSize: AppFontSize.bodyMedium,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }
}
