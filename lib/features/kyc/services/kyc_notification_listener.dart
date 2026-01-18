import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_spacing.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/kyc/domain/entities/kyc_status.dart';
import 'package:parcel_am/core/services/navigation_service/nav_config.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/theme/app_radius.dart';
import 'package:parcel_am/core/theme/app_font_size.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/injection_container.dart';

/// Listens to KYC status changes and shows notifications
class KycNotificationListener extends StatefulWidget {
  final Widget child;

  const KycNotificationListener({
    super.key,
    required this.child,
  });

  @override
  State<KycNotificationListener> createState() =>
      _KycNotificationListenerState();
}

class _KycNotificationListenerState extends State<KycNotificationListener> {
  KycStatus? _previousStatus;
  StreamSubscription? _statusSubscription;
  OverlayEntry? _currentOverlay;

  @override
  void initState() {
    super.initState();
    _initializeListener();
  }

  void _initializeListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final authBloc = context.read<AuthCubit>();
      _statusSubscription = authBloc.stream.listen(_handleStatusChange);

      final currentState = authBloc.state;
      if (currentState is DataState<AuthData> &&
          currentState.data?.user != null) {
        _previousStatus = currentState.data!.user!.kycStatus;
      }
    });
  }

  void _handleStatusChange(BaseState<AuthData> state) {
    if (!mounted) return;

    if (state is DataState<AuthData> && state.data?.user != null) {
      final currentStatus = state.data!.user!.kycStatus;

      if (_previousStatus != null && _previousStatus != currentStatus) {
        _showStatusChangeNotification(currentStatus, _previousStatus!);
      }

      _previousStatus = currentStatus;
    }
  }

  void _showStatusChangeNotification(KycStatus newStatus, KycStatus oldStatus) {
    // Only show notifications for meaningful status changes
    if (!_isSignificantChange(oldStatus, newStatus)) {
      return;
    }

    final notificationData = _getNotificationData(newStatus, oldStatus);
    if (notificationData == null) return;

    if (!mounted) return;

    // Show toast notification
    _showToastNotification(notificationData);

    // Show dialog for critical status changes (approved/rejected)
    if (newStatus == KycStatus.approved || newStatus == KycStatus.rejected) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showStatusChangeDialog(notificationData);
        }
      });
    }
  }

  bool _isSignificantChange(KycStatus oldStatus, KycStatus newStatus) {
    // Don't show notifications for these transitions
    if (oldStatus == KycStatus.pending && newStatus == KycStatus.underReview) {
      return false;
    }
    if (oldStatus == KycStatus.underReview && newStatus == KycStatus.pending) {
      return false;
    }

    return true;
  }

  _NotificationData? _getNotificationData(
      KycStatus newStatus, KycStatus oldStatus) {
    switch (newStatus) {
      case KycStatus.pending:
      case KycStatus.underReview:
        if (oldStatus == KycStatus.notStarted ||
            oldStatus == KycStatus.incomplete) {
          return _NotificationData(
            title: 'Verification Submitted',
            message:
                'Your documents are now under review. We\'ll notify you once complete.',
            backgroundColor: AppColors.info,
            icon: Icons.pending_outlined,
            actionText: null,
          );
        }
        return null;

      case KycStatus.approved:
        return _NotificationData(
          title: 'Verification Approved!',
          message:
              'Your identity has been verified. You now have full access to all features.',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_outline,
          actionText: 'Explore Features',
          actionRoute: Routes.dashboard,
        );

      case KycStatus.rejected:
        return _NotificationData(
          title: 'Verification Issues',
          message:
              'We couldn\'t verify your documents. Please review and resubmit.',
          backgroundColor: AppColors.error,
          icon: Icons.error_outline,
          actionText: 'Resubmit',
          actionRoute: Routes.verification,
        );

      default:
        return null;
    }
  }

  void _showToastNotification(_NotificationData data) {
    // Remove previous overlay if exists
    _currentOverlay?.remove();

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => _KycNotificationToast(
        data: data,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  void _showStatusChangeDialog(_NotificationData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _KycStatusChangeDialog(data: data),
    );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _currentOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _NotificationData {
  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final String? actionText;
  final String? actionRoute;

  _NotificationData({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    this.actionText,
    this.actionRoute,
  });
}

/// Toast notification that slides down from the top
class _KycNotificationToast extends StatefulWidget {
  final _NotificationData data;
  final VoidCallback onDismiss;

  const _KycNotificationToast({
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_KycNotificationToast> createState() => _KycNotificationToastState();
}

class _KycNotificationToastState extends State<_KycNotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _dismiss,
                child: Material(
                  elevation: 8,
                  borderRadius: AppRadius.md,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.data.backgroundColor,
                      borderRadius: AppRadius.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.data.icon,
                          color: AppColors.white,
                          size: 32,
                        ),
                        AppSpacing.horizontalSpacing(SpacingSize.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                widget.data.title,
                                variant: TextVariant.bodyLarge,
                                fontSize: AppFontSize.bodyLarge,
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              AppSpacing.verticalSpacing(SpacingSize.xs),
                              AppText(
                                widget.data.message,
                                variant: TextVariant.bodySmall,
                                fontSize: AppFontSize.md,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.white),
                          onPressed: _dismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog showing detailed KYC status change information
class _KycStatusChangeDialog extends StatelessWidget {
  final _NotificationData data;

  const _KycStatusChangeDialog({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = data.backgroundColor == AppColors.success;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xl,
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: data.backgroundColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 64,
              color: data.backgroundColor,
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.xl),
          AppText(
            data.title,
            variant: TextVariant.titleLarge,
            fontSize: AppFontSize.titleLarge,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText(
            data.message,
            variant: TextVariant.bodyMedium,
            fontSize: AppFontSize.lg,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          if (isApproved) ...[
            AppSpacing.verticalSpacing(SpacingSize.lg),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  const Expanded(
                    child: AppText(
                      'You can now access wallet, payments, and all features',
                      variant: TextVariant.bodySmall,
                      fontSize: AppFontSize.md,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (data.actionText != null && data.actionRoute != null)
          AppButton.text(
            onPressed: () {
              Navigator.of(context).pop();
              sl<NavigationService>().navigateTo(data.actionRoute!);
            },
            child: AppText.bodyMedium(data.actionText!),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: data.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.sm,
            ),
          ),
          child: AppText.bodyMedium(
            'Got it',
            color: AppColors.white,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    );
  }
}
