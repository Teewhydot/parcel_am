/// Example usage of KYC access control system
///
/// This file demonstrates various ways to use the KYC guard system.
/// Delete this file after reviewing the examples.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/travellink/domain/entities/user_entity.dart';
import '../services/auth/auth_guard.dart';
import '../services/auth/kyc_guard.dart';
import '../routes/routes.dart';
import 'kyc_annotation.dart';

/// Example 1: Using KycGuard mixin in a widget
class MyKycProtectedWidget extends StatelessWidget with KycCheckMixin {
  const MyKycProtectedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Check KYC before performing action
        if (!isKycVerified(context)) {
          Get.toNamed(Routes.kycBlocked, arguments: {
            'status': checkKycStatus(context),
          });
          return;
        }
        
        // Proceed with action
        _performKycRequiredAction();
      },
      child: const Text('KYC Required Action'),
    );
  }

  void _performKycRequiredAction() {
    // Your KYC-required logic here
  }
}

/// Example 2: Using protectedRoute widget wrapper
class ExampleKycProtectedScreen extends StatelessWidget {
  const ExampleKycProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KycGuard.instance.protectedRoute(
      context: context,
      child: Scaffold(
        appBar: AppBar(title: const Text('KYC Protected')),
        body: const Center(child: Text('KYC Verified Content')),
      ),
    );
  }
}

/// Example 3: Using AuthGuard with KYC support
class ExampleAuthAndKycProtectedScreen extends StatelessWidget {
  const ExampleAuthAndKycProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthGuard.instance.protectedRoute(
      context: context,
      requireKyc: true,
      allowPendingKyc: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Auth + KYC Protected')),
        body: const Center(child: Text('Authenticated and KYC Verified')),
      ),
    );
  }
}

/// Example 4: Creating KYC-protected routes with GetX
class ExampleRouteConfiguration {
  static List<GetPage> getPages() {
    return [
      // Regular authenticated route
      AuthGuard.createProtectedRoute(
        name: Routes.dashboard,
        page: () => const Scaffold(body: Text('Dashboard')),
      ),
      
      // KYC-protected route (requires verified KYC)
      AuthGuard.createProtectedRoute(
        name: Routes.payment,
        page: () => const Scaffold(body: Text('Payment')),
        requireKyc: true,
      ),
      
      // KYC-protected route (allows pending KYC)
      AuthGuard.createProtectedRoute(
        name: Routes.browseRequests,
        page: () => const Scaffold(body: Text('Browse Requests')),
        requireKyc: true,
        allowPendingKyc: true,
      ),
      
      // Direct KYC-only route (no auth check, useful for specific cases)
      KycGuard.createKycProtectedRoute(
        name: '/kyc-only-feature',
        page: () => const Scaffold(body: Text('KYC Only Feature')),
      ),
    ];
  }
}

/// Example 5: Using annotations (for documentation/metadata)
@KycRequired()
class AnnotatedKycFeature extends StatelessWidget {
  const AnnotatedKycFeature({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation
    return Container();
  }
}

@KycRequired(allowPending: true, message: 'Payment requires KYC')
class AnnotatedPaymentFeature extends StatelessWidget {
  const AnnotatedPaymentFeature({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation
    return Container();
  }
}

/// Example 6: Manual KYC checking in BLoC or business logic
class ExampleService {
  Future<void> performKycRequiredOperation(BuildContext context) async {
    final kycGuard = KycGuard.instance;
    
    // Check KYC status
    final status = kycGuard.checkKycStatus(context);
    
    switch (status) {
      case KycStatus.approved:
        // Proceed with operation
        await _executeOperation();
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        // Show pending message or allow limited access
        _showPendingMessage();
        break;
      case KycStatus.notStarted:
      case KycStatus.incomplete:
      case KycStatus.rejected:
        // Redirect to KYC screen
        Get.toNamed(Routes.kycBlocked, arguments: {'status': status});
        break;
    }
  }

  Future<void> _executeOperation() async {
    // Implementation
  }

  void _showPendingMessage() {
    Get.snackbar('Pending', 'Your KYC is being reviewed');
  }
}

/// Example 7: Using KYC guard in a controller/cubit
class ExampleController extends GetxController with KycCheckMixin {
  void onPaymentButtonPressed(BuildContext context) {
    if (!isKycVerified(context)) {
      Get.snackbar(
        'KYC Required',
        'Please complete KYC verification to make payments',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.toNamed(Routes.verification);
      return;
    }
    
    // Proceed with payment
    _processPayment();
  }

  void _processPayment() {
    // Implementation
  }
}
