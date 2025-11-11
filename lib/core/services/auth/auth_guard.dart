import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import '../../../features/travellink/presentation/bloc/auth/auth_bloc.dart';
import '../../../features/travellink/presentation/bloc/auth/auth_data.dart';
import '../../../core/bloc/base/base_state.dart';
import '../../../features/travellink/domain/entities/user_entity.dart';
import '../../routes/routes.dart';
import 'kyc_guard.dart';

class KycGuard {
  static KycGuard? _instance;
  static KycGuard get instance => _instance ??= KycGuard._();
  
  KycGuard._();

  bool checkKycStatus(BuildContext context, {bool showDialog = true}) {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is DataState<AuthData> && authState.data?.user != null) {
      final user = authState.data!.user!;
      
      if (!user.kycStatus.isVerified) {
        if (showDialog) {
          _showKycRequiredDialog(context, user.kycStatus);
        }
        return false;
      }
      return true;
    }
    
    return false;
  }

  void _showKycRequiredDialog(BuildContext context, KycStatus status) {
    String title;
    String message;
    
    switch (status) {
      case KycStatus.notStarted:
        title = 'KYC Verification Required';
        message = 'Please complete your identity verification to access this feature.';
        break;
      case KycStatus.incomplete:
        title = 'Complete KYC Verification';
        message = 'Your KYC verification is incomplete. Please complete all steps to access this feature.';
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        title = 'Verification In Progress';
        message = 'Your KYC verification is currently under review. You\'ll be notified once it\'s approved.';
        break;
      case KycStatus.rejected:
        title = 'Verification Required';
        message = 'Your KYC verification was not approved. Please submit your information again.';
        break;
      default:
        title = 'Verification Required';
        message = 'Please verify your identity to access this feature.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (status == KycStatus.notStarted || 
              status == KycStatus.incomplete || 
              status == KycStatus.rejected)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed(Routes.verification);
              },
              child: const Text('Start Verification'),
            ),
        ],
      ),
    );
  }

  bool requiresKyc(String routeName) {
    const kycProtectedRoutes = [
      Routes.dashboard,
      Routes.wallet,
      Routes.payment,
      Routes.tracking,
      Routes.browseRequests,
    ];
    
    return kycProtectedRoutes.contains(routeName);
  }
}

class AuthGuard {
  static AuthGuard? _instance;
  static AuthGuard get instance => _instance ??= AuthGuard._();
  
  final KycGuard _kycGuard = KycGuard.instance;
  
  AuthGuard._();

  /// Check if user is authenticated and redirect if not
  bool checkAuthentication(BuildContext context, {bool requireKyc = false, bool allowPendingKyc = false}) {
    final authState = context.read<AuthBloc>().state;
    
    final isAuthenticated = authState is DataState<AuthData> && 
                            authState.data != null && 
                            authState.data!.user != null;
    
    if (!isAuthenticated) {
      // Redirect to login screen
      Get.offAllNamed(Routes.login);
      return false;
    }
    
    // Check KYC if required
    if (requireKyc) {
      return _kycGuard.checkKycAccess(context, allowPending: allowPendingKyc);
    }
    
    return true;
  }

  /// Get authentication-aware route guard
  Widget protectedRoute({
    required BuildContext context,
    required Widget child,
    bool requireKyc = false,
    bool allowPendingKyc = false,
    Widget? loadingWidget,
    Widget? unauthenticatedWidget,
  }) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        final authData = state is DataState<AuthData> ? state.data : null;
        final isAuthenticated = authData != null && authData.user != null;
        
        if (state.isLoading) {
          return loadingWidget ?? const _DefaultLoadingWidget();
        }
        
        if (!isAuthenticated) {
          // Auto-redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.login);
          });
          return unauthenticatedWidget ?? const _DefaultUnauthenticatedWidget();
        }
        
        // Check KYC if required
        if (requireKyc) {
          return _kycGuard.protectedRoute(
            context: context,
            child: child,
            allowPending: allowPendingKyc,
            loadingWidget: loadingWidget,
            blockedWidget: unauthenticatedWidget,
          );
        }
        
        return child;
      },
    );
  }

  /// Check if current route requires authentication
  bool requiresAuthentication(String routeName) {
    const protectedRoutes = [
      Routes.dashboard,
      Routes.tracking,
      Routes.payment,
      Routes.requestDetails,
      Routes.browseRequests,
      Routes.verification,
    ];
    
    return protectedRoutes.contains(routeName);
  }

  /// Create protected GetPage with authentication middleware
  static GetPage createProtectedRoute({
    required String name,
    required Widget Function() page,
    bool requireKyc = false,
    bool allowPendingKyc = false,
    List<GetMiddleware>? middlewares,
    Transition? transition,
    Duration? transitionDuration,
    bool requiresKyc = false,
  }) {
    final allMiddlewares = <GetMiddleware>[
      AuthMiddleware(),
      if (requiresKyc) KycMiddleware(),
      ...?middlewares,
    ];
    
    return GetPage(
      name: name,
      page: page,
      middlewares: allMiddlewares,
      transition: transition,
      transitionDuration: transitionDuration,
    );
  }
}

/// GetX Middleware for route protection with authentication
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;
    
    final authGuard = AuthGuard.instance;
    
    if (authGuard.requiresAuthentication(route)) {
      if (Get.context != null) {
        try {
          final authState = Get.context!.read<AuthBloc>().state;
          final isAuthenticated = authState is DataState<AuthData> && 
                                  authState.data != null && 
                                  authState.data!.user != null;
          
          if (!isAuthenticated) {
            return const RouteSettings(name: Routes.login);
          }
        } catch (e) {
          return const RouteSettings(name: Routes.login);
        }
      }
    }
    
    return null;
  }
}

/// GetX Middleware for KYC-protected routes
class KycMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;
    
    final kycGuard = KycGuard.instance;
    
    if (kycGuard.requiresKyc(route)) {
      if (Get.context != null) {
        try {
          final authState = Get.context!.read<AuthBloc>().state;
          
          if (authState is DataState<AuthData> && authState.data?.user != null) {
            final user = authState.data!.user!;
            
            if (!user.kycStatus.isVerified) {
              if (user.kycStatus == KycStatus.notStarted || 
                  user.kycStatus == KycStatus.incomplete ||
                  user.kycStatus == KycStatus.rejected) {
                return const RouteSettings(name: Routes.verification);
              } else {
                return const RouteSettings(name: Routes.dashboard);
              }
            }
          }
        } catch (e) {
          return const RouteSettings(name: Routes.dashboard);
        }
      }
    }
    
    return null;
  }
}

/// Default loading widget for protected routes
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

/// Default widget shown when user is not authenticated
class _DefaultUnauthenticatedWidget extends StatelessWidget {
  const _DefaultUnauthenticatedWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to access this feature',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Get.offAllNamed(Routes.login);
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
