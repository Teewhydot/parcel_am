# KYC Access Control System ✅

A modular and flexible KYC (Know Your Customer) access control system for Flutter applications using Clean Architecture and BLoC pattern.

## Status: ✅ Fully Implemented

All components of the KYC access control system are now complete and functional:
- ✅ KycGuard middleware with KycCheckMixin
- ✅ KycBlockedScreen for unauthorized access
- ✅ AuthGuard with integrated KYC support
- ✅ KycRequiredAnnotation/decorator for documentation
- ✅ Comprehensive testing suite
- ✅ Multiple integration methods

## Overview

The KYC access control system provides multiple layers of protection for features and routes that require identity verification. It integrates seamlessly with the existing authentication system and offers various methods for implementing KYC checks.

## Components

### 1. KycGuard (`kyc_guard.dart`)

The main guard class providing KYC verification and access control.

**Key Features:**
- Singleton pattern for global access
- `KycCheckMixin` for easy integration
- Widget-based route protection
- GetX middleware support
- Multiple KYC status levels

**KYC Status Levels:**
- `verified`: User has completed and passed KYC verification
- `pending`: KYC submission is under review
- `rejected`: KYC verification was unsuccessful
- `notStarted`: User hasn't started KYC process
- `unknown`: Unable to determine KYC status

### 2. KycBlockedScreen (`kyc_blocked_screen.dart`)

A dedicated screen shown when users attempt to access KYC-protected features without proper verification.

**Features:**
- Status-specific messaging
- Dynamic UI based on KYC status
- Direct navigation to verification
- Return to dashboard option

### 3. Enhanced AuthGuard (`auth_guard.dart`)

Updated to support KYC verification alongside authentication checks.

**New Parameters:**
- `requireKyc`: Enable KYC verification requirement
- `allowPendingKyc`: Allow access with pending KYC status

### 4. KycRequired Annotation (`kyc_annotation.dart`)

Decorator/annotation for marking KYC-protected features.

**Usage:**
```dart
@KycRequired()
class PaymentFeature extends StatelessWidget { }

@KycRequired(allowPending: true, message: 'Custom message')
class BrowseRequestsFeature extends StatelessWidget { }
```

## Usage Examples

### Method 1: Using KycCheckMixin

Add the mixin to any class to get KYC checking capabilities:

```dart
class MyWidget extends StatelessWidget with KycCheckMixin {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (!isKycVerified(context)) {
          Get.toNamed(Routes.kycBlocked, arguments: {
            'status': checkKycStatus(context),
          });
          return;
        }
        performAction();
      },
      child: const Text('KYC Required Action'),
    );
  }
}
```

### Method 2: Widget Wrapper

Wrap your entire screen with KYC protection:

```dart
class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KycGuard.instance.protectedRoute(
      context: context,
      child: Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const PaymentContent(),
      ),
    );
  }
}
```

### Method 3: Combined Auth + KYC Guard

Use AuthGuard with KYC support for double protection:

```dart
class SecureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthGuard.instance.protectedRoute(
      context: context,
      requireKyc: true,
      allowPendingKyc: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Secure Feature')),
        body: const SecureContent(),
      ),
    );
  }
}
```

### Method 4: Route-Level Protection

Protect routes using GetX middleware:

```dart
// Requires verified KYC
AuthGuard.createProtectedRoute(
  name: Routes.payment,
  page: () => const PaymentScreen(),
  requireKyc: true,
),

// Allows pending KYC
AuthGuard.createProtectedRoute(
  name: Routes.browseRequests,
  page: () => const BrowseRequestsScreen(),
  requireKyc: true,
  allowPendingKyc: true,
),

// KYC-only protection (no auth check)
KycGuard.createKycProtectedRoute(
  name: '/special-feature',
  page: () => const SpecialFeatureScreen(),
),
```

### Method 5: Manual Status Checking

For business logic and services:

```dart
class PaymentService {
  Future<void> processPayment(BuildContext context) async {
    final kycGuard = KycGuard.instance;
    final status = kycGuard.checkKycStatus(context);
    
    switch (status) {
      case KycStatus.verified:
        await executePayment();
        break;
      case KycStatus.pending:
        showPendingMessage();
        break;
      default:
        Get.toNamed(Routes.kycBlocked, arguments: {'status': status});
        break;
    }
  }
}
```

### Method 6: Controller/BLoC Integration

Use in GetX controllers or BLoCs:

```dart
class PaymentController extends GetxController with KycCheckMixin {
  void onPayButtonPressed(BuildContext context) {
    if (!isKycVerified(context)) {
      Get.snackbar('KYC Required', 'Complete verification to proceed');
      Get.toNamed(Routes.verification);
      return;
    }
    processPayment();
  }
}
```

## Configuration

### Adding KYC-Protected Routes

In `getx_route_module.dart`:

```dart
static final List<GetPage> routes = [
  // Regular protected route (auth only)
  AuthGuard.createProtectedRoute(
    name: Routes.dashboard,
    page: () => const DashboardScreen(),
  ),
  
  // KYC-protected route
  AuthGuard.createProtectedRoute(
    name: Routes.payment,
    page: () => const PaymentScreen(),
    requireKyc: true,  // Add this
  ),
  
  // KYC blocked screen
  GetPage(
    name: Routes.kycBlocked,
    page: () => const KycBlockedScreen(),
  ),
];
```

### Customizing KYC Requirements

Modify `requiresKyc()` method in `kyc_guard.dart`:

```dart
bool requiresKyc(String routeName) {
  const kycProtectedRoutes = [
    Routes.payment,
    Routes.browseRequests,
    Routes.sendPackage,  // Add more routes
    Routes.becomeDriver,
  ];
  
  return kycProtectedRoutes.contains(routeName);
}
```

## User Entity Requirements

The system expects the `UserEntity` to have:
- `isVerified`: Boolean indicating if user has any verification
- `verificationStatus`: String with values like "verified", "pending", "rejected", "not_started"

Ensure your user model includes these fields:

```dart
class UserEntity {
  final bool isVerified;
  final String verificationStatus;
  // ... other fields
}
```

## Flow Diagram

```
User Action → Check Auth → Check KYC → Grant/Deny Access
                  ↓              ↓
              Login Screen   KYC Blocked Screen
                                 ↓
                           Verification Screen
```

## Best Practices

1. **Use appropriate method**: Choose based on your use case
   - Widget-level: Individual buttons/actions
   - Screen-level: Entire screens
   - Route-level: Navigation protection

2. **Allow pending when appropriate**: Use `allowPending: true` for features that can work with pending verification

3. **Provide clear messaging**: The KycBlockedScreen automatically shows status-specific messages

4. **Test all status levels**: Ensure your app handles all KYC statuses gracefully

5. **Combine with auth checks**: Most KYC-protected features should also require authentication

## Maintenance

### Adding New KYC Levels

To support multi-level KYC (future enhancement):

1. Update `KycStatus` enum in `kyc_guard.dart`
2. Modify `KycRequired` annotation to support level parameter
3. Update checking logic in `checkKycAccess()`

### Customizing UI

Modify `KycBlockedScreen` to match your app's design:
- Update icons, colors, and messaging
- Add custom animations
- Integrate with your design system

## Testing

Example test cases:

```dart
testWidgets('Blocks access when KYC not verified', (tester) async {
  // Setup unverified user
  // Navigate to KYC-protected route
  // Verify redirected to KycBlockedScreen
});

testWidgets('Allows access when KYC verified', (tester) async {
  // Setup verified user
  // Navigate to KYC-protected route
  // Verify access granted
});
```

## Troubleshooting

**Issue**: KYC check always fails
- Ensure AuthBloc is provided in widget tree
- Verify user entity has correct fields
- Check that verificationStatus string matches expected values

**Issue**: Infinite redirect loop
- Verify Routes.kycBlocked is not marked as KYC-protected
- Check that verification screen is accessible without KYC

**Issue**: KYC status not updating
- Ensure user entity is updated in AuthBloc state
- Check that verificationStatus field is being updated from backend

## Related Files

- `lib/core/services/auth/kyc_guard.dart` - Main guard implementation
- `lib/core/services/auth/auth_guard.dart` - Enhanced auth guard with KYC
- `lib/core/constants/kyc_annotation.dart` - Annotations/decorators
- `lib/features/travellink/presentation/screens/kyc_blocked_screen.dart` - Blocked screen UI
- `lib/core/routes/getx_route_module.dart` - Route configuration
- `lib/features/travellink/domain/entities/user_entity.dart` - User model

## Future Enhancements

- Multi-level KYC (Basic, Advanced, Premium)
- Time-based KYC expiration
- Feature-specific KYC requirements
- KYC analytics and tracking
- Offline KYC status caching
