import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../../../features/parcel_am_core/presentation/bloc/auth/auth_data.dart';
import '../../../core/bloc/base/base_state.dart';
import 'package:parcel_am/features/kyc/domain/entities/kyc_status.dart';

/// Simple KYC Guard with realtime stream support for surgical protection
///
/// **Surgical Protection Model:**
/// - Screens always render normally
/// - Individual widgets can be enabled/disabled based on KYC status
/// - Use `context.watchKycAccess` for realtime bool stream
/// - Use `context.watchKycStatus` for detailed status stream
///
/// **Example:**
/// ```dart
/// // Disable button based on KYC
/// StreamBuilder<bool>(
///   stream: context.watchKycAccess,
///   builder: (context, snapshot) {
///     final canAccess = snapshot.data ?? false;
///     return ElevatedButton(
///       onPressed: canAccess ? onPay : null,
///       child: Text('Pay'),
///     );
///   },
/// )
///
/// // Or use KycButton for automatic handling
/// KycButton(
///   onPressed: onPay,
///   child: Text('Pay'),
/// )
/// ```
class KycGuard {
  static KycGuard? _instance;
  static KycGuard get instance => _instance ??= KycGuard._();

  KycGuard._();

  /// Get current KYC status (synchronous)
  KycStatus getStatus(BuildContext context) {
    try {
      final authBloc = context.read<AuthCubit>();
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

  /// Watch KYC status stream (realtime)
  /// Emits current status immediately, then listens for updates
  Stream<KycStatus> watchStatus(BuildContext context) {
    try {
      final authBloc = context.read<AuthCubit>();
      final userId = context.currentUserId;

      if (userId == null) {
        return Stream.value(KycStatus.notStarted);
      }

      // Get current status to emit immediately
      final currentStatus = getStatus(context);

      // Create stream that emits current value first, then updates
      return Stream.multi((controller) {
        // Emit current value immediately
        controller.add(currentStatus);

        // Then listen to updates
        final subscription = authBloc.watchUserData(userId).listen(
          (result) {
            final status = result.fold(
              (failure) => KycStatus.notStarted,
              (userData) => userData.kycStatus,
            );
            controller.add(status);
          },
          onError: controller.addError,
          onDone: controller.close,
        );

        controller.onCancel = () {
          subscription.cancel();
        };
      });
    } catch (e) {
      return Stream.value(KycStatus.notStarted);
    }
  }

  /// Show KYC blocked snackbar using context-based ScaffoldMessenger
  void showKycBlockedSnackbar(BuildContext context) {
    context.showSnackbar(
      message: 'Please complete your KYC verification to access this feature.',
      color: const Color(0xFFFF9800), // Warning/amber color
      duration: 3,
    );
  }
}

/// Global KYC Status Monitor Widget
/// Place this at the app root to enable global KYC monitoring
///
/// **Usage:**
/// ```dart
/// MaterialApp(
///   home: KycStatusMonitor(
///     child: YourApp(),
///   ),
/// )
/// ```
class KycStatusMonitor extends StatelessWidget {
  final Widget child;

  const KycStatusMonitor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KycStatus>(
      stream: context.watchKycStatus,
      builder: (context, snapshot) {
        // Just pass through the child - this monitors globally
        // Individual widgets use surgical protection
        return child;
      },
    );
  }
}

/// Button with automatic KYC protection
/// Automatically disables when KYC not verified and shows snackbar on tap
///
/// **Usage:**
/// ```dart
/// KycButton(
///   onPressed: () => processPayment(),
///   child: Text('Pay Now'),
/// )
/// ```
class KycButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const KycButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.watchKycAccess,
      builder: (context, snapshot) {
        final hasAccess = snapshot.data ?? false;

        return AppButton.primary(
          onPressed: hasAccess
              ? onPressed
              : () {
                  // Show snackbar when clicked while disabled
                  KycGuard.instance.showKycBlockedSnackbar(context);
                },
          child: child,
        );
      },
    );
  }
}

/// Gesture detector with automatic KYC protection
/// Blocks tap and shows snackbar when KYC not verified
///
/// **Usage:**
/// ```dart
/// KycGestureDetector(
///   onTap: () => navigateToFeature(),
///   child: CustomCard(...),
/// )
/// ```
class KycGestureDetector extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final HitTestBehavior? behavior;

  const KycGestureDetector({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.watchKycAccess,
      builder: (context, snapshot) {
        final hasAccess = snapshot.data ?? false;

        return GestureDetector(
          onTap: hasAccess
              ? onTap
              : () {
                  // Show snackbar when tapped while blocked
                  KycGuard.instance.showKycBlockedSnackbar(context);
                },
          // Use opaque behavior to ensure taps are detected on the entire area
          behavior: behavior ?? HitTestBehavior.opaque,
          child: child,
        );
      },
    );
  }
}

/// BuildContext extension for easy KYC access
/// Provides both synchronous and stream-based access to KYC status
extension KycContext on BuildContext {
  /// Get current KYC status (synchronous)
  KycStatus get kycStatus => KycGuard.instance.getStatus(this);

  /// Watch KYC status stream (realtime) - returns detailed status
  Stream<KycStatus> get watchKycStatus => KycGuard.instance.watchStatus(this);

  /// Watch KYC access stream (realtime) - returns bool for simple enable/disable
  Stream<bool> get watchKycAccess {
    return watchKycStatus.map((status) => status.isVerified);
  }

  /// Check if KYC verified (synchronous)
  bool get isKycVerified => kycStatus.isVerified;

  /// Get KYC access (synchronous) - bool for simple checks
  bool get kycAccess => kycStatus.isVerified;
}
