import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:parcel_am/core/theme/app_colors.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/utils/logger.dart';
import '../base/base_state.dart';

/// A simplified version of EnhancedBlocManager that maintains core functionality
/// without excessive configuration options
class BlocManager<T extends BlocBase<S>, S extends BaseState>
    extends StatelessWidget {
  /// The BLoC instance to manage
  final T bloc;

  /// Child widget to display
  final Widget child;

  /// Custom builder for the widget tree
  final Widget Function(BuildContext context, S state)? builder;

  /// Custom listener for state changes
  final void Function(BuildContext context, S state)? listener;

  /// Custom error handler
  final void Function(BuildContext context, S state)? onError;

  /// Custom success handler
  final void Function(BuildContext context, S state)? onSuccess;

  /// Whether to show loading overlay during loading states
  final bool showLoadingIndicator;

  /// Whether to show success or error messages
  final bool showResultErrorNotifications;
  final bool showResultSuccessNotifications;

  /// Custom loading widget
  final Widget? loadingWidget;

  /// Whether to enable pull-to-refresh
  final bool enablePullToRefresh;

  /// Pull-to-refresh callback
  final Future<void> Function()? onRefresh;

  const BlocManager({
    super.key,
    required this.bloc,
    required this.child,
    this.builder,
    this.listener,
    this.onError,
    this.onSuccess,
    this.showLoadingIndicator = true,
    this.showResultErrorNotifications = true,
    this.showResultSuccessNotifications = false,
    this.loadingWidget,
    this.enablePullToRefresh = false,
    this.onRefresh,
  });

  /// Log Firestore-specific errors with detailed information
  static void _logFirestoreError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    // Log all errors to console
    Logger.logError('❌ Error: $errorMessage');

    // Check for Firestore index errors
    if (lowerError.contains('index') ||
        lowerError.contains('composite') ||
        lowerError.contains('requires an index')) {
      print('🔍 FIRESTORE INDEX ERROR DETECTED:');
      print('   Error: $errorMessage');
      print('   Action Required: Create the missing index in Firebase Console');
      print('   Visit: https://console.firebase.google.com/project/_/firestore/indexes');
    }

    // Check for permission errors
    if (lowerError.contains('permission') || lowerError.contains('permission-denied')) {
      print('🔒 FIRESTORE PERMISSION ERROR:');
      print('   Error: $errorMessage');
      print('   Check your Firestore security rules');
    }

    // Check for document not found errors
    if (lowerError.contains('not-found') || lowerError.contains('not found')) {
      print('📄 FIRESTORE DOCUMENT NOT FOUND:');
      print('   Error: $errorMessage');
      print('   The requested document does not exist');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<T>.value(
      value: bloc,
      child: BlocConsumer<T, S>(
        buildWhen: (previous, current) {
          // Always rebuild for initial load, loading states, errors, and empty states
          if (previous is InitialState ||
              current is InitialState ||
              current is LoadingState ||
              current is ErrorState ||
              current is EmptyState) {
            return true;
          }

          // For loaded states, check if we should rebuild
          if (current is LoadedState && previous is LoadedState) {
            // Don't rebuild if returning cached data with same content
            if (current.isFromCache == true && previous.data == current.data) {
              return false;
            }
          }

          return true;
        },
        builder: (context, state) {
          // Handle custom builder if provided
          final Widget contentWidget =
              builder != null ? builder!(context, state) : child;

          // Apply loading overlay if needed
          if (showLoadingIndicator && state.isLoading) {
            return LoadingOverlay(
              isLoading: true,
              color: AppColors.primary.withValues(alpha: 0.5),
              progressIndicator: SpinKitCircle(color: AppColors.white, size: 50.0),
              child: contentWidget,
            );
          }

          // Handle pull-to-refresh
          if (enablePullToRefresh && onRefresh != null) {
            return RefreshIndicator(
              onRefresh: onRefresh!,
              child: contentWidget,
            );
          }

          return contentWidget;
        },
        listener: (context, state) {
          // Handle error states
          if (state.isError) {
            final String errorMessage =
                state.errorMessage ?? AppConstants.defaultErrorMessage;

            // Log Firestore-specific errors to console
            _logFirestoreError(errorMessage);

            if (showResultErrorNotifications) {
              DFoodUtils.showSnackBar(errorMessage, AppColors.error);
            }
            if (onError != null) {
              onError!(context, state);
            }
          }

          // Handle success states
          if (state.isSuccess) {
            Logger.logSuccess("Success condition met in BlocManager");
            if (onSuccess != null) {
              onSuccess!(context, state);
            }
            if (showResultSuccessNotifications) {
              DFoodUtils.showSnackBar(
                state.successMessage ?? AppConstants.defaultSuccessMessage,
              AppColors.primaryLight,
              );
            }
          }
          //Handle loaded state
          if (state is LoadedState) {
            Logger.logSuccess("Success condition met in BlocManager");
            if (onSuccess != null) {
              onSuccess!(context, state);
            }
            if (showResultSuccessNotifications) {
              DFoodUtils.showSnackBar(
                state.successMessage ?? AppConstants.defaultSuccessMessage,
                AppColors.primaryLight,
              );
            }
          }

          // Call custom listener if provided
          if (listener != null) {
            listener!(context, state);
          }
        },
      ),
    );
  }
}
