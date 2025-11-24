import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import '../../../features/parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import '../../../features/parcel_am_core/presentation/bloc/auth/auth_data.dart';
import '../../../core/bloc/base/base_state.dart';
import '../../../core/domain/entities/kyc_status.dart';
import '../../routes/routes.dart';

/// Mixin to provide realtime KYC checking capabilities to any class
///
/// **REALTIME REACTIVE IMPLEMENTATION**
/// This mixin provides stream-based methods that automatically update UI
/// when KYC status changes in realtime - no manual refresh needed.
///
/// **Primary Methods (Use these for UI components):**
/// - `watchKycStatus()` - Returns `Stream<KycStatus>` for realtime status updates
/// - `watchIsKycVerified()` - Returns `Stream<bool>` for realtime verification status
/// - `watchIsKycPending()` - Returns `Stream<bool>` for realtime pending status
///
/// **Example Usage:**
/// ```dart
/// // Reactive button that automatically updates
/// StreamBuilder<KycStatus>(
///   stream: watchKycStatus(context),
///   builder: (context, snapshot) {
///     final status = snapshot.data;
///     return ElevatedButton(
///       onPressed: status?.isVerified == true ? onAction : null,
///       child: Text('Action'),
///     );
///   },
/// )
///
/// // Or use the convenience builder
/// kycStatusBuilder(
///   context: context,
///   builder: (context, status) {
///     return Text('KYC Status: ${status.name}');
///   },
/// )
/// ```
///
/// **Synchronous Methods (Only for middleware/guards):**
/// - `checkKycStatus()` - Gets current status without watching
/// - `isKycVerified()` - Checks if verified without watching
/// - `isKycPending()` - Checks if pending without watching
mixin KycCheckMixin {
  /// Watch KYC status for realtime updates (returns a Stream)
  /// This is the primary method for getting KYC status
  Stream<KycStatus> watchKycStatus(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      final userId = context.currentUserId;

      if (userId == null) {
        return Stream.value(KycStatus.notStarted);
      }

      // Return stream that maps user data to KYC status
      return authBloc.watchUserData(userId).map((result) {
        return result.fold(
          (failure) => KycStatus.notStarted,
          (userData) => userData.kycStatus,
        );
      });
    } catch (e) {
      return Stream.value(KycStatus.notStarted);
    }
  }

  /// Watch if user has completed KYC verification (realtime)
  Stream<bool> watchIsKycVerified(BuildContext context) {
    return watchKycStatus(context).map((status) => status.isVerified);
  }

  /// Watch if KYC is pending (realtime)
  Stream<bool> watchIsKycPending(BuildContext context) {
    return watchKycStatus(context).map((status) => status == KycStatus.pending);
  }

  /// Check KYC status from user entity (synchronous - for middleware/guards only)
  /// Prefer using watchKycStatus for UI components
  KycStatus checkKycStatus(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      final state = authBloc.state;

      // Get current user data from state
      if (state is DataState<AuthData>) {
        final user = state.data?.user;
        if (user != null) {
          return user.kycStatus;
        }
      }

      return KycStatus.notStarted;
    } catch (e) {
      return KycStatus.notStarted;
    }
  }

  /// Check if user has completed KYC verification (synchronous - for middleware/guards only)
  /// Prefer using watchIsKycVerified for UI components
  bool isKycVerified(BuildContext context) {
    return checkKycStatus(context).isVerified;
  }

  /// Check if KYC is pending (synchronous - for middleware/guards only)
  /// Prefer using watchIsKycPending for UI components
  bool isKycPending(BuildContext context) {
    return checkKycStatus(context) == KycStatus.pending;
  }
}

/// Guard for KYC-protected routes and features
class KycGuard with KycCheckMixin {
  static KycGuard? _instance;
  static KycGuard get instance => _instance ??= KycGuard._();
  
  KycGuard._();

  /// Watch KYC access status in realtime (returns `Stream<bool>`)
  /// This is the primary method for monitoring KYC access
  Stream<bool> watchKycAccess(BuildContext context, {bool allowPending = false}) {
    return watchKycStatus(context).map((status) {
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
      return false;
    });
  }

  /// Check if user has KYC verification and redirect if not (synchronous - for immediate checks only)
  /// Prefer using watchKycAccess for UI components
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

  /// Get KYC-aware route guard widget (uses realtime stream)
  Widget protectedRoute({
    required BuildContext context,
    required Widget child,
    bool allowPending = false,
    Widget? loadingWidget,
    Widget? blockedWidget,
  }) {
    return StreamBuilder<KycStatus>(
      stream: watchKycStatus(context),
      builder: (context, snapshot) {
        // Show loading while waiting for initial data
        if (!snapshot.hasData) {
          return loadingWidget ?? const _DefaultLoadingWidget();
        }

        // Handle errors
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.login);
          });
          return blockedWidget ?? const _DefaultBlockedWidget();
        }

        final status = snapshot.data!;

        // Allow verified users
        if (status.isVerified) {
          return child;
        }

        // Allow pending if configured
        if (allowPending && status == KycStatus.pending) {
          return child;
        }

        // Redirect to KYC blocked screen for other statuses
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

  /// Reactive widget builder that automatically updates based on realtime KYC status
  /// Use this to build any widget that needs to react to KYC status changes
  Widget kycStatusBuilder({
    required BuildContext context,
    required Widget Function(BuildContext, KycStatus) builder,
    Widget? loadingWidget,
  }) {
    return StreamBuilder<KycStatus>(
      stream: watchKycStatus(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return loadingWidget ?? const CircularProgressIndicator();
        }
        return builder(context, snapshot.data!);
      },
    );
  }

  /// Widget that listens to KYC status changes and automatically navigates when status changes
  /// This ensures the UI always reflects the current KYC state
  Widget kycStatusListener({
    required BuildContext context,
    required Widget child,
    bool autoNavigateOnChange = true,
  }) {
    return StreamBuilder<KycStatus>(
      stream: watchKycStatus(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return child;
        }

        final status = snapshot.data!;

        // Auto-navigate to appropriate screen based on status change
        if (autoNavigateOnChange) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (status == KycStatus.notStarted ||
                status == KycStatus.incomplete ||
                status == KycStatus.rejected) {
              Get.offAllNamed(Routes.verification);
            } else if (status == KycStatus.pending || status == KycStatus.underReview) {
              // Show toast for pending status
              _showVerificationInProgressToast();
            }
          });
        }

        return child;
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
        final status = checkKycStatus(Get.context!);

        // If KYC verified, allow navigation
        if (status.isVerified) {
          return null;
        }

        // If pending is allowed, allow navigation
        if (allowPending && (status == KycStatus.pending || status == KycStatus.underReview)) {
          return null;
        }

        // Not verified - show snackbar and block navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          KycGuard.instance._showVerificationInProgressToast();
        });

        // Block navigation by staying on current route
        final currentRoute = Get.routing.current;
        if (currentRoute.isNotEmpty && currentRoute != route) {
          return RouteSettings(name: currentRoute);
        }

        return const RouteSettings(name: Routes.dashboard);
      }
    }

    return null;
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

/// Extension on BuildContext for easy access to realtime KYC status streams
/// This makes it super convenient to access KYC status anywhere in your app
extension KycContextExtension on BuildContext {
  /// Watch KYC status in realtime (automatically updates when status changes)
  Stream<KycStatus> get watchKyc {
    final authBloc = read<AuthBloc>();
    final userId = currentUserId;

    if (userId == null) {
      return Stream.value(KycStatus.notStarted);
    }

    return authBloc.watchUserData(userId).map((result) {
      return result.fold(
        (failure) => KycStatus.notStarted,
        (userData) => userData.kycStatus,
      );
    });
  }

  /// Watch if KYC is verified in realtime
  Stream<bool> get watchKycVerified {
    return watchKyc.map((status) => status.isVerified);
  }

  /// Watch if KYC is pending in realtime
  Stream<bool> get watchKycPending {
    return watchKyc.map((status) => status == KycStatus.pending);
  }

  /// Get current KYC status synchronously (for immediate checks only)
  KycStatus get currentKycStatus {
    try {
      final authBloc = read<AuthBloc>();
      final state = authBloc.state;

      if (state is DataState<AuthData>) {
        final user = state.data?.user;
        if (user != null) {
          return user.kycStatus;
        }
      }

      return KycStatus.notStarted;
    } catch (e) {
      return KycStatus.notStarted;
    }
  }
}
