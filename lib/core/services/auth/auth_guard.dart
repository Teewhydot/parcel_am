import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import '../../../features/travellink/presentation/bloc/auth/auth_bloc.dart';
import '../../../features/travellink/presentation/bloc/auth/auth_state.dart';
import '../../routes/routes.dart';

class AuthGuard {
  static AuthGuard? _instance;
  static AuthGuard get instance => _instance ??= AuthGuard._();
  
  AuthGuard._();

  /// Check if user is authenticated and redirect if not
  bool checkAuthentication(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    
    if (!authState.isAuthenticated) {
      // Redirect to login screen
      Get.offAllNamed(Routes.login);
      return false;
    }
    
    return true;
  }

  /// Get authentication-aware route guard
  Widget protectedRoute({
    required BuildContext context,
    required Widget child,
    Widget? loadingWidget,
    Widget? unauthenticatedWidget,
  }) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.loading:
          case AuthStatus.initial:
            return loadingWidget ?? const _DefaultLoadingWidget();
            
          case AuthStatus.authenticated:
            return child;
            
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            // Auto-redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAllNamed(Routes.login);
            });
            return unauthenticatedWidget ?? const _DefaultUnauthenticatedWidget();
            
          default:
            return unauthenticatedWidget ?? const _DefaultUnauthenticatedWidget();
        }
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
    List<GetMiddleware>? middlewares,
    Transition? transition,
    Duration? transitionDuration,
  }) {
    return GetPage(
      name: name,
      page: page,
      middlewares: [
        AuthMiddleware(),
        ...?middlewares,
      ],
      transition: transition,
      transitionDuration: transitionDuration,
    );
  }
}

/// GetX Middleware for route protection
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;
    
    final authGuard = AuthGuard.instance;
    
    if (authGuard.requiresAuthentication(route)) {
      // Check if we have access to auth state
      if (Get.context != null) {
        try {
          final authState = Get.context!.read<AuthBloc>().state;
          
          if (!authState.isAuthenticated) {
            return const RouteSettings(name: Routes.login);
          }
        } catch (e) {
          // If BLoC is not available, redirect to login for safety
          return const RouteSettings(name: Routes.login);
        }
      }
    }
    
    return null; // Continue with the original route
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