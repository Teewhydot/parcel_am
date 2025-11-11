import 'package:get/get.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/features/travellink/presentation/screens/dashboard_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/login_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/onboarding_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/payment_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/request_details_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/tracking_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/verification_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/browse_requests_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/kyc_blocked_screen.dart';
import 'package:parcel_am/features/travellink/presentation/screens/wallet_screen.dart';

import '../../features/travellink/presentation/screens/splash_screen.dart';
import '../services/auth/auth_guard.dart';

class GetXRouteModule {
  static const Transition _transition = Transition.rightToLeft;
  static const Duration _transitionDuration = Duration(milliseconds: 300);
  static final List<GetPage> routes = [
    GetPage(
      name: Routes.initial,
      page: () => const SplashScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.dashboard,
      page: () => const DashboardScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.payment,
      page: () => const PaymentScreen(),
      requireKyc: true,
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.requestDetails,
      page: () => const RequestDetailsScreen(requestId: ""),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.tracking,
      page: () => const TrackingScreen(packageId: "packageId"),
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.verification,
      page: () => const VerificationScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.browseRequests,
      page: () => const BrowseRequestsScreen(),
      requireKyc: true,
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    GetPage(
      name: Routes.kycBlocked,
      page: () => const KycBlockedScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.wallet,
      page: () {
        // Get current user ID from auth service or pass via route arguments
        final userId = Get.arguments as String? ?? '';
        return WalletScreen(userId: userId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
  ];
}
