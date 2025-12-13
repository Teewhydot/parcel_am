import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import '../../../features/parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import '../../../features/parcel_am_core/presentation/bloc/auth/auth_data.dart';
import '../../../core/bloc/base/base_state.dart';
import '../../../injection_container.dart';
import '../../routes/routes.dart';
import '../navigation_service/nav_config.dart';
import 'kyc_guard.dart';

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
      sl<NavigationService>().navigateAndReplaceAll(Routes.login);
      return false;
    }
    
    // Check KYC if required
    if (requireKyc) {
      final status = _kycGuard.getStatus(context);
      if (!status.isVerified) {
        _kycGuard.showKycBlockedSnackbar();
        return false;
      }
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
            sl<NavigationService>().navigateAndReplaceAll(Routes.login);
          });
          return unauthenticatedWidget ?? const _DefaultUnauthenticatedWidget();
        }
        
        // Check KYC if required
        if (requireKyc) {
          return StreamBuilder(
            stream: _kycGuard.watchStatus(context),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return loadingWidget ?? const _DefaultLoadingWidget();
              }

              final status = snapshot.data!;
              if (status.isVerified) {
                return child;
              }

              // Not verified - redirect to blocked screen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _kycGuard.showKycBlockedSnackbar();
              });

              return unauthenticatedWidget ?? const _DefaultUnauthenticatedWidget();
            },
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
      Routes.chatsList,
      Routes.chat,
    ];
    
    return protectedRoutes.contains(routeName);
  }

  /// Create protected GetPage with authentication middleware
  /// Note: KYC protection should be done at widget level using KycProtectedWidget
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
                sl<NavigationService>().navigateAndReplaceAll(Routes.login);
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
