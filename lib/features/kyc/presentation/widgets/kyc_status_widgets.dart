import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/errors/failures.dart' show Failure;
import 'package:parcel_am/features/parcel_am_core/data/models/user_model.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/routes/routes.dart';
import '../../../../injection_container.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_data.dart';
import '../../../../core/bloc/base/base_state.dart';

/// Compact badge showing KYC status, typically used in app bars
class KycStatusBadge extends StatelessWidget {
  final KycStatus status;
  final bool compact;
  
  const KycStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: compact ? AppRadius.md : AppRadius.lg,
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: compact ? 14 : 16,
            color: _getStatusColor(status),
          ),
          SizedBox(width: compact ? 4 : 6),
          AppText(
            status.displayName,
            variant: TextVariant.bodySmall,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(status),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
      case KycStatus.incomplete:
        return AppColors.textSecondary;
      case KycStatus.pending:
      case KycStatus.underReview:
        return AppColors.warning;
      case KycStatus.approved:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return Icons.shield_outlined;
      case KycStatus.incomplete:
        return Icons.error_outline;
      case KycStatus.pending:
      case KycStatus.underReview:
        return Icons.pending;
      case KycStatus.approved:
        return Icons.verified;
      case KycStatus.rejected:
        return Icons.cancel;
    }
  }
}

/// Clickable KYC status indicator that navigates to verification screen
class KycStatusIndicator extends StatelessWidget {
  const KycStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        if (state is! DataState<AuthData> || state.data?.user == null) {
          return const SizedBox.shrink();
        }
        
        final user = state.data!.user!;
        
        return GestureDetector(
          onTap: () {
            if (user.kycStatus.requiresAction) {
              sl<NavigationService>().navigateTo(Routes.verification);
            }
          },
          child: KycStatusBadge(
            status: user.kycStatus,
            compact: true,
          ),
        );
      },
    );
  }
}

/// Full-width banner showing KYC status with action button
class KycStatusBanner extends StatefulWidget {
  final bool showOnApproved;
  final EdgeInsets? margin;
  
  const KycStatusBanner({
    super.key,
    this.showOnApproved = false,
    this.margin,
  });

  @override
  State<KycStatusBanner> createState() => _KycStatusBannerState();
}

class _KycStatusBannerState extends State<KycStatusBanner> {
      late Stream<Either<Failure, UserModel>> _kycStatusStream;


@override
  void initState() {
    super.initState();
     final authBloc = context.read<AuthBloc>();
    final userId = authBloc.state is LoadedState<AuthData>
        ? (authBloc.state as LoadedState<AuthData>).data?.user?.uid ?? ''
        : '';
    _kycStatusStream = context.read<AuthBloc>().watchUserData(userId);
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, UserModel>>(
      stream: _kycStatusStream,
      builder: (context, state) {
        
        final user = state.data?.fold(
          (failure) => null,
          (userModel) => userModel,
        );
        final status = user?.kycStatus ?? KycStatus.notStarted;
        
        if (!widget.showOnApproved && status == KycStatus.approved) {
          return const SizedBox.shrink();
        }
        
        return GestureDetector(
          onTap: status.requiresAction
              ? () => sl<NavigationService>().navigateTo(Routes.verification)
              : null,
          child: Container(
            margin: widget.margin ?? AppSpacing.paddingMD,
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              border: Border.all(color: _getStatusColor(status), width: 1),
              borderRadius: AppRadius.md,
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.labelLarge(
                        _getStatusTitle(status),
                        color: _getStatusColor(status),
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.xs),
                      AppText.bodySmall(
                        _getStatusMessage(status),
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                if (status.requiresAction) ...[
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  Icon(
                    Icons.chevron_right,
                    color: _getStatusColor(status),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
      case KycStatus.incomplete:
        return AppColors.error;
      case KycStatus.pending:
      case KycStatus.underReview:
        return AppColors.warning;
      case KycStatus.approved:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return Icons.shield_outlined;
      case KycStatus.incomplete:
        return Icons.error_outline;
      case KycStatus.pending:
      case KycStatus.underReview:
        return Icons.pending_outlined;
      case KycStatus.approved:
        return Icons.verified_user;
      case KycStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusTitle(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'Verify Your Identity';
      case KycStatus.incomplete:
        return 'Complete Verification';
      case KycStatus.pending:
      case KycStatus.underReview:
        return 'Verification In Progress';
      case KycStatus.approved:
        return 'Verified';
      case KycStatus.rejected:
        return 'Verification Required';
    }
  }

  String _getStatusMessage(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'Complete KYC verification to access all features';
      case KycStatus.incomplete:
        return 'Finish your verification to unlock full access';
      case KycStatus.pending:
      case KycStatus.underReview:
        return 'We\'re reviewing your documents. This usually takes 24-48 hours.';
      case KycStatus.approved:
        return 'Your identity has been verified';
      case KycStatus.rejected:
        return 'Please resubmit your verification documents';
    }
  }
}

/// Card widget showing detailed KYC status information
class KycStatusCard extends StatelessWidget {
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  
  const KycStatusCard({
    super.key,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        if (state is! DataState<AuthData> || state.data?.user == null) {
          return const SizedBox.shrink();
        }
        
        final user = state.data!.user!;
        final status = user.kycStatus;
        
        return Container(
          margin: margin ?? AppSpacing.paddingMD,
          padding: padding ?? AppSpacing.paddingLG,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.lg,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: AppRadius.md,
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 28,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleMedium(
                          _getStatusTitle(status),
                          color: AppColors.onSurface,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        KycStatusBadge(status: status, compact: true),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyMedium(
                _getStatusDescription(status),
                color: AppColors.onSurfaceVariant,
              ),
              if (status.requiresAction) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => sl<NavigationService>().navigateTo(Routes.verification),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(status),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.sm,
                      ),
                    ),
                    child: AppText.bodyMedium(
                      _getActionButtonText(status),
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
      case KycStatus.incomplete:
        return AppColors.error;
      case KycStatus.pending:
      case KycStatus.underReview:
        return AppColors.warning;
      case KycStatus.approved:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return Icons.shield_outlined;
      case KycStatus.incomplete:
        return Icons.error_outline;
      case KycStatus.pending:
      case KycStatus.underReview:
        return Icons.pending_outlined;
      case KycStatus.approved:
        return Icons.verified_user;
      case KycStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusTitle(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'Identity Verification Required';
      case KycStatus.incomplete:
        return 'Complete Your Verification';
      case KycStatus.pending:
      case KycStatus.underReview:
        return 'Verification In Progress';
      case KycStatus.approved:
        return 'Identity Verified';
      case KycStatus.rejected:
        return 'Verification Rejected';
    }
  }

  String _getStatusDescription(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'To access all features and ensure secure transactions, please verify your identity by completing our KYC process.';
      case KycStatus.incomplete:
        return 'You started the verification process but haven\'t completed it yet. Please finish all required steps to unlock full access.';
      case KycStatus.pending:
      case KycStatus.underReview:
        return 'Your documents are currently being reviewed by our team. This process typically takes 24-48 hours. We\'ll notify you once complete.';
      case KycStatus.approved:
        return 'Your identity has been successfully verified. You now have full access to all features including wallet, payments, and tracking.';
      case KycStatus.rejected:
        return 'We were unable to verify your identity with the submitted documents. Please review the requirements and submit again.';
    }
  }

  String _getActionButtonText(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'Start Verification';
      case KycStatus.incomplete:
        return 'Continue Verification';
      case KycStatus.rejected:
        return 'Resubmit Documents';
      default:
        return 'View Details';
    }
  }
}

/// Simple icon with tooltip showing KYC status
class KycStatusIcon extends StatelessWidget {
  final double size;
  
  const KycStatusIcon({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        if (state is! DataState<AuthData> || state.data?.user == null) {
          return const SizedBox.shrink();
        }
        
        final user = state.data!.user!;
        final status = user.kycStatus;
        
        return Tooltip(
          message: _getTooltipMessage(status),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: size,
          ),
        );
      },
    );
  }

  Color _getStatusColor(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
      case KycStatus.incomplete:
        return AppColors.textSecondary;
      case KycStatus.pending:
      case KycStatus.underReview:
        return AppColors.warning;
      case KycStatus.approved:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return Icons.shield_outlined;
      case KycStatus.incomplete:
        return Icons.error_outline;
      case KycStatus.pending:
      case KycStatus.underReview:
        return Icons.pending;
      case KycStatus.approved:
        return Icons.verified_user;
      case KycStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getTooltipMessage(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'KYC not started';
      case KycStatus.incomplete:
        return 'KYC incomplete';
      case KycStatus.pending:
      case KycStatus.underReview:
        return 'KYC under review';
      case KycStatus.approved:
        return 'KYC verified';
      case KycStatus.rejected:
        return 'KYC rejected';
    }
  }
}
