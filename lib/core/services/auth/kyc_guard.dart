import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import '../../../features/travellink/presentation/bloc/auth/auth_bloc.dart';
import '../../../features/travellink/presentation/bloc/auth/auth_data.dart';
import '../../../features/travellink/domain/entities/user_entity.dart';
import '../../../core/bloc/base/base_state.dart';
import '../../../core/domain/entities/kyc_status.dart';
import '../../routes/routes.dart';

/// Mixin to provide KYC checking capabilities to any class
mixin KycCheckMixin {
  /// Check KYC status from user entity
  KycStatus checkKycStatus(BuildContext context) {
    try {
      final authState = context.read<AuthBloc>().state;

      if (authState is DataState<AuthData>) {
        final user = authState.data?.user;
        if (user != null) {
          return user.kycStatus;
        }
      }

      return KycStatus.notStarted;
    } catch (e) {
      return KycStatus.notStarted;
    }
  }

  /// Check if user has completed KYC verification
  bool isKycVerified(BuildContext context) {
    return checkKycStatus(context).isVerified;
  }

  /// Check if KYC is pending
  bool isKycPending(BuildContext context) {
    return checkKycStatus(context) == KycStatus.pending;
  }
}

/// Guard for KYC-protected routes and features
class KycGuard with KycCheckMixin {
  static KycGuard? _instance;
  static KycGuard get instance => _instance ??= KycGuard._();
  
  KycGuard._();

  /// Check if user has KYC verification and redirect if not
  bool checkKycAccess(BuildContext context, {bool allowPending = false}) {
    final status = checkKycStatus(context);

    if (status.isVerified) {
      return true;
    }

    if (allowPending && status == KycStatus.pending) {
      return true;
    }

    // If verification is in progress, show toast and block access
    if (status == KycStatus.pending || status == KycStatus.underReview) {
      _showVerificationInProgressToast();
      return false;
    }

    // Redirect to KYC blocked screen with status for other cases
    Get.toNamed(
      Routes.kycBlocked,
      arguments: {'status': status},
    );
    return false;
  }

  /// Show toast message when verification is in progress
  void _showVerificationInProgressToast() {
    Get.snackbar(
      'Verification In Progress',
      'Your KYC verification is currently being reviewed. Please wait for approval.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFF9800), // Orange color
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.hourglass_empty,
        color: Colors.white,
      ),
    );
  }

  /// Get KYC-aware route guard widget
  Widget protectedRoute({
    required BuildContext context,
    required Widget child,
    bool allowPending = false,
    Widget? loadingWidget,
    Widget? blockedWidget,
  }) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        final authData = state is DataState<AuthData> ? state.data : null;
        final user = authData?.user;

        if (state.isLoading) {
          return loadingWidget ?? const _DefaultLoadingWidget();
        }

        if (user == null) {
          // Not authenticated, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.login);
          });
          return blockedWidget ?? const _DefaultBlockedWidget();
        }

        final status = user.kycStatus;

        if (status.isVerified) {
          return child;
        }

        if (allowPending && status == KycStatus.pending) {
          return child;
        }

        // Redirect to KYC blocked screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed(
            Routes.kycBlocked,
            arguments: {'status': status},
          );
        });

        return blockedWidget ?? const _DefaultBlockedWidget();
      },
    );
  }

  /// Check if current route requires KYC
  bool requiresKyc(String routeName) {
    const kycProtectedRoutes = [
      Routes.payment,
      Routes.browseRequests,
      Routes.createParcel,
      Routes.wallet,
      Routes.tracking,
    ];

    return kycProtectedRoutes.contains(routeName);
  }

  /// Create KYC-protected GetPage with middleware
  static GetPage createKycProtectedRoute({
    required String name,
    required Widget Function() page,
    bool allowPending = false,
    List<GetMiddleware>? middlewares,
    Transition? transition,
    Duration? transitionDuration,
  }) {
    return GetPage(
      name: name,
      page: page,
      middlewares: [
        KycMiddleware(allowPending: allowPending),
        ...?middlewares,
      ],
      transition: transition,
      transitionDuration: transitionDuration,
    );
  }
}

/// GetX Middleware for KYC-protected routes
class KycMiddleware extends GetMiddleware with KycCheckMixin {
  final bool allowPending;

  KycMiddleware({this.allowPending = false});

  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;

    final kycGuard = KycGuard.instance;

    if (kycGuard.requiresKyc(route)) {
      if (Get.context != null) {
        try {
          final status = checkKycStatus(Get.context!);

          if (status.isVerified) {
            return null; // Allow access
          }

          if (allowPending && status == KycStatus.pending) {
            return null; // Allow access
          }

          // If verification is in progress, show toast and stay on current page
          if (status == KycStatus.pending || status == KycStatus.underReview) {
            KycGuard.instance._showVerificationInProgressToast();
            return RouteSettings(name: Get.currentRoute); // Stay on current route
          }

          // Redirect to KYC blocked screen for other statuses
          return RouteSettings(
            name: Routes.kycBlocked,
            arguments: {'status': status},
          );
        } catch (e) {
          // If unable to check, redirect to blocked screen
          return const RouteSettings(name: Routes.kycBlocked);
        }
      }
    }

    return null; // Continue with the original route
  }
}

/// Default loading widget for KYC-protected routes
class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Default widget shown when KYC is required
class _DefaultBlockedWidget extends StatelessWidget {
  const _DefaultBlockedWidget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
