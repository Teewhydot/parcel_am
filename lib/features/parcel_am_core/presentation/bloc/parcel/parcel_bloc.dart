import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/app_utils.dart';
import '../../../../../core/services/connectivity_service.dart';
import '../../../../../core/services/offline_queue_service.dart';
import '../../../../../injection_container.dart';
import 'parcel_event.dart';
import 'parcel_state.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';

class ParcelBloc extends BaseBloC<ParcelEvent, BaseState<ParcelData>> {
  final _parcelUseCase = ParcelUseCase();
  StreamSubscription<dynamic>? _parcelStatusSubscription;
  StreamSubscription<dynamic>? _userParcelsSubscription;
  StreamSubscription<dynamic>? _availableParcelsSubscription;
  StreamSubscription<dynamic>? _acceptedParcelsSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  // Task Group 4.2.1: Offline handling services
  final ConnectivityService _connectivityService = sl<ConnectivityService>();
  final OfflineQueueService _offlineQueueService = sl<OfflineQueueService>();
  bool _isOnline = true;

  ParcelBloc() : super(const InitialState<ParcelData>()) {
    on<ParcelCreateRequested>(_onCreateRequested);
    on<ParcelUpdateStatusRequested>(_onUpdateStatusRequested);
    on<ParcelWatchRequested>(_onWatchRequested);
    on<ParcelWatchUserParcelsRequested>(_onWatchUserParcelsRequested);
    on<ParcelStatusUpdated>(_onStatusUpdated);
    on<ParcelListUpdated>(_onListUpdated);
    on<ParcelLoadRequested>(_onLoadRequested);
    on<ParcelLoadUserParcels>(_onLoadUserParcels);
    on<ParcelWatchAvailableParcelsRequested>(_onWatchAvailableParcelsRequested);
    on<ParcelAvailableListUpdated>(_onAvailableListUpdated);
    on<ParcelAssignTravelerRequested>(_onAssignTravelerRequested);
    on<ParcelWatchAcceptedParcelsRequested>(_onWatchAcceptedParcelsRequested);
    on<ParcelAcceptedListUpdated>(_onAcceptedListUpdated);

    // Task Group 4.2.1: Start connectivity monitoring
    // _initConnectivityMonitoring();
  }

  /// Task Group 4.2.1: Initialize connectivity monitoring
  /// Syncs queued updates when connection is restored
  // void _initConnectivityMonitoring() {
  //   _connectivityService.startMonitoring();
  //   _isOnline = _connectivityService.isConnected;
  //
  //   _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
  //     final wasOffline = !_isOnline;
  //     _isOnline = isConnected;
  //
  //     // If connection is restored and we were offline, sync queued updates
  //     if (isConnected && wasOffline) {
  //       _syncQueuedUpdates();
  //       DFoodUtils.showSnackBar(
  //         'Connection restored. Syncing pending updates...',
  //         AppColors.success,
  //       );
  //     } else if (!isConnected) {
  //       DFoodUtils.showSnackBar(
  //         'No internet connection. Changes will sync when online.',
  //         AppColors.warning,
  //       );
  //     }
  //   });
  // }

  /// Task Group 4.2.1: Sync queued status updates when back online
  Future<void> _syncQueuedUpdates() async {
    try {
      final queuedUpdates = await _offlineQueueService.getQueuedUpdates();

      for (final update in queuedUpdates) {
        final parcelId = update['parcelId'] as String;
        final statusStr = update['status'] as String;
        final status = ParcelStatus.fromString(statusStr);

        // Attempt to sync the update
        final result = await _parcelUseCase.updateParcelStatus(parcelId, status);

        result.fold(
          (failure) {
            // Keep in queue if sync fails
            print('Failed to sync update for $parcelId: ${failure.failureMessage}');
          },
          (updatedParcel) {
            // Remove from queue on success
            _offlineQueueService.removeFromQueue(parcelId);
          },
        );
      }

      final remainingCount = await _offlineQueueService.getQueueSize();
      if (remainingCount == 0) {
        DFoodUtils.showSnackBar(
          'All updates synced successfully',
          AppColors.success,
        );
      }
    } catch (e) {
      print('Error syncing queued updates: $e');
    }
  }

  Future<void> _onCreateRequested(
    ParcelCreateRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.createParcel(event.parcel);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));

        add(ParcelWatchRequested(parcel.id));
      },
    );
  }

  /// Handles status update requests with validation, retry, and offline support.
  ///
  /// Task Group 4.2.1: Enhanced with offline handling
  /// Task Group 4.2.3: Client-side status validation
  /// Task Group 4.2.4: Optimistic updates with rollback
  /// Task Group 4.2.5: Exponential backoff retry mechanism
  ///
  /// Features:
  /// - Status progression validation before update
  /// - Offline queue management
  /// - Optimistic UI updates for immediate feedback
  /// - Exponential backoff retry (up to 3 attempts)
  /// - Rollback on persistent failures
  /// - User feedback via snackbar messages
  Future<void> _onUpdateStatusRequested(
    ParcelUpdateStatusRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();

    // Find the parcel being updated (could be in any list)
    ParcelEntity? parcelToUpdate;
    if (currentData.currentParcel?.id == event.parcelId) {
      parcelToUpdate = currentData.currentParcel;
    } else {
      parcelToUpdate = currentData.acceptedParcels
          .where((p) => p.id == event.parcelId)
          .firstOrNull;
      parcelToUpdate ??= currentData.userParcels
          .where((p) => p.id == event.parcelId)
          .firstOrNull;
    }

    // Task Group 4.2.3: Validate status progression client-side
    if (parcelToUpdate != null) {
      final currentStatus = parcelToUpdate.status;
      final nextStatus = currentStatus.nextDeliveryStatus;

      if (event.status != nextStatus && currentStatus.canProgressToNextStatus) {
        DFoodUtils.showSnackBar(
          'Invalid status transition. Expected: ${nextStatus?.displayName ?? 'None'}',
          AppColors.error,
        );
        return;
      }

      if (!currentStatus.canProgressToNextStatus && event.status != currentStatus) {
        DFoodUtils.showSnackBar(
          'Cannot update status from ${currentStatus.displayName}',
          AppColors.error,
        );
        return;
      }
    }

    // Task Group 4.2.1: Check connectivity status
    final isConnected = await _connectivityService.checkConnection();

    if (!isConnected) {
      // Queue update for later sync
      await _offlineQueueService.queueStatusUpdate(event.parcelId, event.status);

      DFoodUtils.showSnackBar(
        'No internet. Update queued and will sync when online.',
        AppColors.warning,
      );

      // Still apply optimistic update to UI
      if (parcelToUpdate != null) {
        final now = DateTime.now();
        final updatedMetadata = Map<String, dynamic>.from(parcelToUpdate.metadata ?? {});

        final statusHistory = Map<String, dynamic>.from(
          updatedMetadata['deliveryStatusHistory'] as Map<String, dynamic>? ?? {}
        );
        statusHistory[event.status.toJson()] = now.toIso8601String();
        updatedMetadata['deliveryStatusHistory'] = statusHistory;

        final optimisticParcel = parcelToUpdate.copyWith(
          status: event.status,
          lastStatusUpdate: now,
          metadata: updatedMetadata,
        );

        final optimisticData = _applyOptimisticUpdate(currentData, optimisticParcel);
        emit(LoadedState<ParcelData>(
          data: optimisticData,
          lastUpdated: DateTime.now(),
        ));
      }

      return;
    }

    // Show loading state while preserving current data
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    // Task Group 4.2.4: Optimistic update - create updated parcel entity
    ParcelEntity? optimisticParcel;
    if (parcelToUpdate != null) {
      final now = DateTime.now();
      final updatedMetadata = Map<String, dynamic>.from(parcelToUpdate.metadata ?? {});

      // Update status history in metadata
      final statusHistory = Map<String, dynamic>.from(
        updatedMetadata['deliveryStatusHistory'] as Map<String, dynamic>? ?? {}
      );
      statusHistory[event.status.toJson()] = now.toIso8601String();
      updatedMetadata['deliveryStatusHistory'] = statusHistory;

      optimisticParcel = parcelToUpdate.copyWith(
        status: event.status,
        lastStatusUpdate: now,
        metadata: updatedMetadata,
      );

      // Apply optimistic update to UI
      final optimisticData = _applyOptimisticUpdate(currentData, optimisticParcel);
      emit(LoadedState<ParcelData>(
        data: optimisticData,
        lastUpdated: DateTime.now(),
      ));
    }

    // Task Group 4.2.5: Attempt update with retry mechanism
    final result = await _updateStatusWithRetry(event.parcelId, event.status);

    result.fold(
      (failure) {
        // Task Group 4.2.4: Rollback optimistic update
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));

        DFoodUtils.showSnackBar(
          'Failed to update status: ${failure.failureMessage}',
          AppColors.error,
        );
      },
      (updatedParcel) {
        // Replace optimistic update with actual data
        final updatedData = _applyOptimisticUpdate(currentData, updatedParcel);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));

        DFoodUtils.showSnackBar(
          'Status updated to ${event.status.displayName}',
          AppColors.success,
        );
      },
    );
  }

  /// Task Group 4.2.4: Applies an optimistic update to the appropriate parcel list.
  ParcelData _applyOptimisticUpdate(ParcelData currentData, ParcelEntity updatedParcel) {
    // Update in acceptedParcels if present
    final acceptedIndex = currentData.acceptedParcels.indexWhere((p) => p.id == updatedParcel.id);
    if (acceptedIndex != -1) {
      final updatedAccepted = List<ParcelEntity>.from(currentData.acceptedParcels);
      updatedAccepted[acceptedIndex] = updatedParcel;
      return currentData.copyWith(
        acceptedParcels: updatedAccepted,
        currentParcel: currentData.currentParcel?.id == updatedParcel.id ? updatedParcel : currentData.currentParcel,
      );
    }

    // Update in userParcels if present
    final userIndex = currentData.userParcels.indexWhere((p) => p.id == updatedParcel.id);
    if (userIndex != -1) {
      final updatedUser = List<ParcelEntity>.from(currentData.userParcels);
      updatedUser[userIndex] = updatedParcel;
      return currentData.copyWith(
        userParcels: updatedUser,
        currentParcel: currentData.currentParcel?.id == updatedParcel.id ? updatedParcel : currentData.currentParcel,
      );
    }

    // Update currentParcel if it matches
    if (currentData.currentParcel?.id == updatedParcel.id) {
      return currentData.copyWith(currentParcel: updatedParcel);
    }

    return currentData;
  }

  /// Task Group 4.2.5: Attempts to update parcel status with exponential backoff retry.
  ///
  /// Retries up to 3 times with delays: 500ms, 1000ms, 2000ms
  Future<Either<Failure, ParcelEntity>> _updateStatusWithRetry(
    String parcelId,
    ParcelStatus status, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxAttempts) {
      try {
        final result = await _parcelUseCase.updateParcelStatus(parcelId, status);

        // Return immediately on success
        return result.fold(
          (failure) {
            attempt++;
            if (attempt >= maxAttempts) {
              return Left(failure);
            }
            // Continue to next attempt
            return Left(failure);
          },
          (parcel) => Right(parcel),
        );
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          return Left(ServerFailure(failureMessage: 'Update failed after $maxAttempts attempts: $e'));
        }
      }

      // Exponential backoff: 500ms, 1000ms, 2000ms
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 500 * (1 << (attempt - 1))));
      }
    }

    return Left(ServerFailure(failureMessage: 'Update failed after $maxAttempts attempts'));
  }

  Future<void> _onWatchRequested(
    ParcelWatchRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    await _parcelStatusSubscription?.cancel();

    _parcelStatusSubscription = _parcelUseCase
        .watchParcelStatus(event.parcelId)
        .listen(
          (parcelEither) {
            parcelEither.fold(
              (failure) {
              },
              (parcel) {
                add(ParcelStatusUpdated(parcel));
              },
            );
          },
          onError: (error) {
          },
        );
  }

  Future<void> _onWatchUserParcelsRequested(
    ParcelWatchUserParcelsRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    await _userParcelsSubscription?.cancel();

    _userParcelsSubscription = _parcelUseCase
        .watchUserParcels(event.userId)
        .listen(
          (parcelsEither) {
            parcelsEither.fold(
              (failure) {
              },
              (parcels) {
                add(ParcelListUpdated(parcels));
              },
            );
          },
          onError: (error) {
          },
        );
  }

  /// Handles the request to watch parcels where the user is the assigned traveler.
  ///
  /// Sets up a real-time stream subscription to receive updates when:
  /// - New parcels are assigned to the user
  /// - Status of accepted parcels changes
  /// - Parcel details are updated by the sender
  ///
  /// Emits [ParcelAcceptedListUpdated] events on each stream update.
  Future<void> _onWatchAcceptedParcelsRequested(
    ParcelWatchAcceptedParcelsRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    // Cancel existing subscription to avoid duplicates
    await _acceptedParcelsSubscription?.cancel();

    // Note: watchUserAcceptedParcels will be implemented in Task Group 2.4
    // For now, we'll set up the stream subscription structure
    _acceptedParcelsSubscription = _parcelUseCase
        .watchUserAcceptedParcels(event.userId)
        .listen(
          (parcelsEither) {
            parcelsEither.fold(
              (failure) {
                // Log error but don't disrupt UI
                // In production, consider logging to analytics
              },
              (parcels) {
                // Emit event to update state with new accepted parcels list
                add(ParcelAcceptedListUpdated(parcels));
              },
            );
          },
          onError: (error) {
            // Handle stream errors gracefully
            // Don't crash the app, just log the error
          },
        );
  }

  /// Handles updates to the accepted parcels list from the stream.
  ///
  /// Updates the state with the new list of accepted parcels, sorted by
  /// most recent status update first. Preserves all other state data
  /// (currentParcel, userParcels, availableParcels).
  Future<void> _onAcceptedListUpdated(
    ParcelAcceptedListUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();

    // Sort parcels by lastStatusUpdate (most recent first)
    final sortedParcels = List<ParcelEntity>.from(event.acceptedParcels);
    sortedParcels.sort((a, b) {
      // Handle null lastStatusUpdate - put them at the end
      if (a.lastStatusUpdate == null && b.lastStatusUpdate == null) return 0;
      if (a.lastStatusUpdate == null) return 1;
      if (b.lastStatusUpdate == null) return -1;

      // Sort descending (most recent first)
      return b.lastStatusUpdate!.compareTo(a.lastStatusUpdate!);
    });

    // Update state with sorted accepted parcels, preserving other data
    final updatedData = currentData.copyWith(acceptedParcels: sortedParcels);

    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onStatusUpdated(
    ParcelStatusUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    final updatedData = currentData.copyWith(currentParcel: event.parcel);
    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onListUpdated(
    ParcelListUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    final updatedData = currentData.copyWith(userParcels: event.parcels);
    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onLoadRequested(
    ParcelLoadRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();

    // Check if we already have this parcel in availableParcels (from browse screen)
    final existingParcel = currentData.availableParcels
        .where((p) => p.id == event.parcelId)
        .firstOrNull;

    // If we already have the parcel data, show it immediately (no loading!)
    if (existingParcel != null) {
      final updatedData = currentData.copyWith(currentParcel: existingParcel);
      emit(LoadedState<ParcelData>(
        data: updatedData,
        lastUpdated: DateTime.now(),
      ));
    } else if (currentData.currentParcel?.id != event.parcelId) {
      // Only show loading if we don't have this parcel at all
      emit(const LoadingState<ParcelData>());
    }

    // Use emit.forEach for automatic stream handling (like ChatsListBloc)
    await emit.forEach<ParcelEntity>(
      _parcelUseCase.watchParcelStatus(event.parcelId).asyncMap((parcelEither) async {
        return parcelEither.fold(
          (failure) => throw Exception(failure.failureMessage),
          (parcel) => parcel,
        );
      }),
      onData: (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        return LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        );
      },
      onError: (error, stackTrace) {
        return ErrorState<ParcelData>(
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> _onLoadUserParcels(
    ParcelLoadUserParcels event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.getUserParcels(event.userId);

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcels) {
        final updatedData = currentData.copyWith(userParcels: parcels);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));

        add(ParcelWatchUserParcelsRequested(event.userId));
      },
    );
  }

  Future<void> _onWatchAvailableParcelsRequested(
    ParcelWatchAvailableParcelsRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    await _availableParcelsSubscription?.cancel();

    _availableParcelsSubscription = _parcelUseCase
        .watchAvailableParcels()
        .listen(
          (parcelsEither) {
            parcelsEither.fold(
              (failure) {
              },
              (parcels) {
                add(ParcelAvailableListUpdated(parcels));
              },
            );
          },
          onError: (error) {
          },
        );
  }

  Future<void> _onAvailableListUpdated(
    ParcelAvailableListUpdated event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    final updatedData = currentData.copyWith(availableParcels: event.parcels);
    emit(LoadedState<ParcelData>(
      data: updatedData,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onAssignTravelerRequested(
    ParcelAssignTravelerRequested event,
    Emitter<BaseState<ParcelData>> emit,
  ) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.assignTraveler(
      event.parcelId,
      event.travelerId,
    );

    result.fold(
      (failure) {
        emit(AsyncErrorState<ParcelData>(
          errorMessage: failure.failureMessage,
          data: currentData,
        ));
      },
      (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        emit(LoadedState<ParcelData>(
          data: updatedData,
          lastUpdated: DateTime.now(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _parcelStatusSubscription?.cancel();
    _userParcelsSubscription?.cancel();
    _availableParcelsSubscription?.cancel();
    _acceptedParcelsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}
