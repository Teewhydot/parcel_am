import 'package:dartz/dartz.dart';
import '../../../../../core/bloc/base/base_bloc.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/app_utils.dart';
import '../../../../../core/services/connectivity_service.dart';
import '../../../../../core/services/offline_queue_service.dart';
import '../../../../../injection_container.dart';
import 'parcel_state.dart';
import '../../../domain/entities/parcel_entity.dart';
import '../../../domain/usecases/parcel_usecase.dart';
import '../../../domain/usecases/escrow_usecase.dart';
import '../../../domain/usecases/wallet_usecase.dart';
import 'package:uuid/uuid.dart';

class ParcelCubit extends BaseCubit<BaseState<ParcelData>> {
  final _parcelUseCase = ParcelUseCase();
  final _escrowUseCase = EscrowUseCase();
  final _walletUseCase = WalletUseCase();
  static const _uuid = Uuid();

  final ConnectivityService _connectivityService = sl<ConnectivityService>();
  final OfflineQueueService _offlineQueueService = sl<OfflineQueueService>();

  ParcelCubit() : super(const InitialState<ParcelData>());

  /// Creates a new parcel with balance hold.
  Future<void> createParcel(ParcelEntity parcel) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    // Generate parcel ID upfront for use as reference in wallet hold
    final parcelId = _uuid.v4();
    final idempotencyKey = 'parcel_hold_$parcelId';

    // Calculate total amount (price + service fee)
    final parcelPrice = parcel.price ?? 0.0;
    const serviceFee = 150.0;
    final totalAmount = parcelPrice + serviceFee;

    // 1. Hold balance first before creating parcel
    final holdResult = await _walletUseCase.holdBalance(
      parcel.sender.userId,
      totalAmount,
      parcelId,
      idempotencyKey,
    );

    // If hold fails, emit error and return without creating parcel
    final holdFailed = holdResult.fold((failure) {
      emit(
        AsyncErrorState<ParcelData>(
          errorMessage: 'Failed to hold balance: ${failure.failureMessage}',
          data: currentData,
        ),
      );
      DFoodUtils.showSnackBar(
        'Insufficient balance to create parcel',
        AppColors.error,
      );
      return true;
    }, (_) => false);

    if (holdFailed) return;

    // 2. Create parcel with the pre-generated ID
    final parcelWithId = parcel.copyWith(id: parcelId);
    final result = await _parcelUseCase.createParcel(parcelWithId);

    result.fold(
      (failure) {
        // If parcel creation fails, we should release the held balance
        _walletUseCase.releaseBalance(
          parcel.sender.userId,
          totalAmount,
          parcelId,
          'parcel_release_$parcelId',
        );
        emit(
          AsyncErrorState<ParcelData>(
            errorMessage: failure.failureMessage,
            data: currentData,
          ),
        );
      },
      (createdParcel) {
        final updatedData = currentData.copyWith(currentParcel: createdParcel);
        emit(
          LoadedState<ParcelData>(
            data: updatedData,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Updates parcel status with validation, retry, and offline support.
  ///
  /// Features:
  /// - Status progression validation before update
  /// - Offline queue management
  /// - Optimistic UI updates for immediate feedback
  /// - Exponential backoff retry (up to 3 attempts)
  /// - Rollback on persistent failures
  /// - User feedback via snackbar messages
  Future<void> updateParcelStatus(String parcelId, ParcelStatus status) async {
    final currentData = state.data ?? const ParcelData();

    // Find the parcel being updated (could be in any list)
    ParcelEntity? parcelToUpdate;
    if (currentData.currentParcel?.id == parcelId) {
      parcelToUpdate = currentData.currentParcel;
    } else {
      parcelToUpdate = currentData.acceptedParcels
          .where((p) => p.id == parcelId)
          .firstOrNull;
      parcelToUpdate ??= currentData.userParcels
          .where((p) => p.id == parcelId)
          .firstOrNull;
    }

    // Validate status progression client-side
    if (parcelToUpdate != null) {
      final currentStatus = parcelToUpdate.status;
      final nextStatus = currentStatus.nextDeliveryStatus;

      if (status != nextStatus && currentStatus.canProgressToNextStatus) {
        DFoodUtils.showSnackBar(
          'Invalid status transition. Expected: ${nextStatus?.displayName ?? 'None'}',
          AppColors.error,
        );
        return;
      }

      if (!currentStatus.canProgressToNextStatus && status != currentStatus) {
        DFoodUtils.showSnackBar(
          'Cannot update status from ${currentStatus.displayName}',
          AppColors.error,
        );
        return;
      }
    }

    // Check connectivity status
    final isConnected = await _connectivityService.checkConnection();

    if (!isConnected) {
      // Queue update for later sync
      await _offlineQueueService.queueStatusUpdate(parcelId, status);

      DFoodUtils.showSnackBar(
        'No internet. Update queued and will sync when online.',
        AppColors.warning,
      );

      // Still apply optimistic update to UI
      if (parcelToUpdate != null) {
        final now = DateTime.now();
        final updatedMetadata = Map<String, dynamic>.from(
          parcelToUpdate.metadata ?? {},
        );

        final statusHistory = Map<String, dynamic>.from(
          updatedMetadata['deliveryStatusHistory'] as Map<String, dynamic>? ??
              {},
        );
        statusHistory[status.toJson()] = now.toIso8601String();
        updatedMetadata['deliveryStatusHistory'] = statusHistory;

        final optimisticParcel = parcelToUpdate.copyWith(
          status: status,
          lastStatusUpdate: now,
          metadata: updatedMetadata,
        );

        final optimisticData = _applyOptimisticUpdate(
          currentData,
          optimisticParcel,
        );
        emit(
          LoadedState<ParcelData>(
            data: optimisticData,
            lastUpdated: DateTime.now(),
          ),
        );
      }

      return;
    }

    // Show loading state while preserving current data and tracking which parcel is updating
    emit(
      AsyncLoadingState<ParcelData>(
        data: currentData.copyWith(updatingParcelId: parcelId),
      ),
    );

    // Optimistic update - create updated parcel entity
    ParcelEntity? optimisticParcel;
    if (parcelToUpdate != null) {
      final now = DateTime.now();
      final updatedMetadata = Map<String, dynamic>.from(
        parcelToUpdate.metadata ?? {},
      );

      // Update status history in metadata
      final statusHistory = Map<String, dynamic>.from(
        updatedMetadata['deliveryStatusHistory'] as Map<String, dynamic>? ?? {},
      );
      statusHistory[status.toJson()] = now.toIso8601String();
      updatedMetadata['deliveryStatusHistory'] = statusHistory;

      optimisticParcel = parcelToUpdate.copyWith(
        status: status,
        lastStatusUpdate: now,
        metadata: updatedMetadata,
      );

      // Apply optimistic update to UI
      final optimisticData = _applyOptimisticUpdate(
        currentData,
        optimisticParcel,
      );
      emit(
        LoadedState<ParcelData>(
          data: optimisticData,
          lastUpdated: DateTime.now(),
        ),
      );
    }

    // Attempt update with retry mechanism
    final result = await _updateStatusWithRetry(parcelId, status);

    result.fold(
      (failure) {
        emit(
          AsyncErrorState<ParcelData>(
            errorMessage: failure.failureMessage,
            data: currentData.copyWith(clearUpdatingParcelId: true),
          ),
        );

        DFoodUtils.showSnackBar(
          'Failed to update status: ${failure.failureMessage}',
          AppColors.error,
        );
      },
      (updatedParcel) {
        final data = state.data ?? const ParcelData();
        emit(
          LoadedState<ParcelData>(
            data: data.copyWith(clearUpdatingParcelId: true),
            lastUpdated: DateTime.now(),
          ),
        );

        DFoodUtils.showSnackBar(
          'Status updated to ${status.displayName}',
          AppColors.success,
        );
      },
    );
  }

  /// Applies an optimistic update to the appropriate parcel list.
  ParcelData _applyOptimisticUpdate(
    ParcelData currentData,
    ParcelEntity updatedParcel,
  ) {
    // Update in acceptedParcels if present
    final acceptedIndex = currentData.acceptedParcels.indexWhere(
      (p) => p.id == updatedParcel.id,
    );
    if (acceptedIndex != -1) {
      final updatedAccepted = List<ParcelEntity>.from(
        currentData.acceptedParcels,
      );
      updatedAccepted[acceptedIndex] = updatedParcel;
      return currentData.copyWith(
        acceptedParcels: updatedAccepted,
        currentParcel: currentData.currentParcel?.id == updatedParcel.id
            ? updatedParcel
            : currentData.currentParcel,
      );
    }

    // Update in userParcels if present
    final userIndex = currentData.userParcels.indexWhere(
      (p) => p.id == updatedParcel.id,
    );
    if (userIndex != -1) {
      final updatedUser = List<ParcelEntity>.from(currentData.userParcels);
      updatedUser[userIndex] = updatedParcel;
      return currentData.copyWith(
        userParcels: updatedUser,
        currentParcel: currentData.currentParcel?.id == updatedParcel.id
            ? updatedParcel
            : currentData.currentParcel,
      );
    }

    // Update currentParcel if it matches
    if (currentData.currentParcel?.id == updatedParcel.id) {
      return currentData.copyWith(currentParcel: updatedParcel);
    }

    return currentData;
  }

  /// Attempts to update parcel status with exponential backoff retry.
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
        final result = await _parcelUseCase.updateParcelStatus(
          parcelId,
          status,
        );

        // Return immediately on success
        return result.fold((failure) {
          attempt++;
          if (attempt >= maxAttempts) {
            return Left(failure);
          }
          // Continue to next attempt
          return Left(failure);
        }, (parcel) => Right(parcel));
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          return Left(
            ServerFailure(
              failureMessage: 'Update failed after $maxAttempts attempts: $e',
            ),
          );
        }
      }

      // Exponential backoff: 500ms, 1000ms, 2000ms
      if (attempt < maxAttempts) {
        await Future.delayed(
          Duration(milliseconds: 500 * (1 << (attempt - 1))),
        );
      }
    }

    return Left(
      ServerFailure(
        failureMessage: 'Update failed after $maxAttempts attempts',
      ),
    );
  }

  /// Loads a specific parcel by ID.
  Future<void> loadParcel(String parcelId) async {
    final currentData = state.data ?? const ParcelData();

    // Check if we already have this parcel in availableParcels (from browse screen)
    final existingParcel = currentData.availableParcels
        .where((p) => p.id == parcelId)
        .firstOrNull;

    // If we already have the parcel data, show it immediately (no loading!)
    if (existingParcel != null) {
      final updatedData = currentData.copyWith(currentParcel: existingParcel);
      emit(
        LoadedState<ParcelData>(data: updatedData, lastUpdated: DateTime.now()),
      );
      return;
    }

    // Show loading while preserving existing data
    if (currentData.currentParcel?.id != parcelId) {
      emit(AsyncLoadingState<ParcelData>(data: currentData));
    }

    // Fetch parcel from repository
    final result = await _parcelUseCase.getParcel(parcelId);
    result.fold(
      (failure) {
        emit(
          AsyncErrorState<ParcelData>(
            errorMessage: failure.failureMessage,
            data: currentData,
          ),
        );
      },
      (parcel) {
        final updatedData = currentData.copyWith(currentParcel: parcel);
        emit(
          LoadedState<ParcelData>(
            data: updatedData,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Loads all parcels created by the user.
  Future<void> loadUserParcels(String userId) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.getUserParcels(userId);

    result.fold(
      (failure) {
        emit(
          AsyncErrorState<ParcelData>(
            errorMessage: failure.failureMessage,
            data: currentData,
          ),
        );
      },
      (parcels) {
        final updatedData = currentData.copyWith(userParcels: parcels);
        emit(
          LoadedState<ParcelData>(
            data: updatedData,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Assigns a traveler to a parcel.
  Future<void> assignTraveler(String parcelId, String travelerId) async {
    final currentData = state.data ?? const ParcelData();
    emit(AsyncLoadingState<ParcelData>(data: currentData));

    final result = await _parcelUseCase.assignTraveler(parcelId, travelerId);

    result.fold(
      (failure) {
        emit(
          AsyncErrorState<ParcelData>(
            errorMessage: failure.failureMessage,
            data: currentData,
          ),
        );
      },
      (parcel) {
        // Add parcel to acceptedParcels immediately for instant UI update
        // The Firestore listener will also update, but this ensures immediate feedback
        final updatedAcceptedParcels = List<ParcelEntity>.from(
          currentData.acceptedParcels,
        );
        // Remove if already exists (shouldn't happen, but safety check)
        updatedAcceptedParcels.removeWhere((p) => p.id == parcel.id);
        // Add to beginning of list (most recent first)
        updatedAcceptedParcels.insert(0, parcel);

        final updatedData = currentData.copyWith(
          currentParcel: parcel,
          acceptedParcels: updatedAcceptedParcels,
        );
        emit(
          LoadedState<ParcelData>(
            data: updatedData,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  /// Confirms delivery and releases payment to courier.
  ///
  /// Flow:
  /// 1. Validates the parcel is in awaitingConfirmation status
  /// 2. Updates parcel status to 'delivered'
  /// 3. Clears sender's held balance (the money is transferred out)
  /// 4. Moves traveler's pending balance to available balance
  /// 5. Releases escrow payment
  /// 6. Shows success/error feedback to user
  Future<void> confirmDelivery(String parcelId, String escrowId) async {
    final currentData = state.data ?? const ParcelData();

    // Set loading state with parcel ID tracking
    emit(
      AsyncLoadingState<ParcelData>(
        data: currentData.copyWith(updatingParcelId: parcelId),
      ),
    );

    // Find the parcel being confirmed
    ParcelEntity? parcelToConfirm;
    if (currentData.currentParcel?.id == parcelId) {
      parcelToConfirm = currentData.currentParcel;
    } else {
      parcelToConfirm = currentData.userParcels
          .where((p) => p.id == parcelId)
          .firstOrNull;
    }

    // Validate parcel status
    if (parcelToConfirm != null &&
        parcelToConfirm.status != ParcelStatus.awaitingConfirmation) {
      emit(
        AsyncErrorState<ParcelData>(
          errorMessage: 'Parcel is not awaiting confirmation',
          data: currentData.copyWith(clearUpdatingParcelId: true),
        ),
      );
      return;
    }

    // Get parcel price and traveler ID for balance transfers
    final parcelPrice = parcelToConfirm?.price ?? 0.0;
    final travelerId = parcelToConfirm?.travelerId;
    final senderId = parcelToConfirm?.sender.userId;

    try {
      // 1. Update parcel status to delivered
      final parcelResult = await _parcelUseCase.updateParcelStatus(
        parcelId,
        ParcelStatus.delivered,
      );

      await parcelResult.fold(
        (failure) async {
          emit(
            AsyncErrorState<ParcelData>(
              errorMessage: failure.failureMessage,
              data: currentData.copyWith(clearUpdatingParcelId: true),
            ),
          );
          DFoodUtils.showSnackBar(
            'Failed to confirm delivery: ${failure.failureMessage}',
            AppColors.error,
          );
        },
        (updatedParcel) async {
          // 2. Clear sender's held balance (money is transferred out)
          if (senderId != null && parcelPrice > 0) {
            final totalAmount = parcelPrice + 150.0; // price + service fee
            final senderClearResult = await _walletUseCase.clearHeldBalance(
              senderId,
              totalAmount,
              parcelId,
              'delivery_confirm_sender_$parcelId',
            );

            senderClearResult.fold((failure) {
              DFoodUtils.showSnackBar(
                'Delivery confirmed! Sender balance update pending.',
                AppColors.warning,
              );
            }, (_) {});
          }

          // 3. Move traveler's pending balance to available
          if (travelerId != null && parcelPrice > 0) {
            final travelerReleaseResult = await _walletUseCase.releaseBalance(
              travelerId,
              parcelPrice,
              parcelId,
              'delivery_confirm_traveler_$parcelId',
            );

            travelerReleaseResult.fold((failure) {
              DFoodUtils.showSnackBar(
                'Delivery confirmed! Traveler payment pending.',
                AppColors.warning,
              );
            }, (_) {});
          }

          // 4. Release escrow payment
          final escrowResult = await _escrowUseCase.releaseEscrow(escrowId);

          escrowResult.fold(
            (failure) {
              // Log escrow failure but delivery is confirmed
              DFoodUtils.showSnackBar(
                'Delivery confirmed! Payment release pending.',
                AppColors.warning,
              );
            },
            (escrow) {
              DFoodUtils.showSnackBar(
                'Delivery confirmed! Payment released to courier.',
                AppColors.success,
              );
            },
          );

          // Clear updating state only - Firestore stream will update the UI
          final data = state.data ?? const ParcelData();
          emit(
            LoadedState<ParcelData>(
              data: data.copyWith(clearUpdatingParcelId: true),
              lastUpdated: DateTime.now(),
            ),
          );
        },
      );
    } catch (e) {
      emit(
        AsyncErrorState<ParcelData>(
          errorMessage: e.toString(),
          data: currentData.copyWith(clearUpdatingParcelId: true),
        ),
      );
      DFoodUtils.showSnackBar('Error confirming delivery: $e', AppColors.error);
    }
  }

  /// Cancels a parcel and releases held balance back to available.
  ///
  /// Flow:
  /// 1. Validates the parcel can be cancelled (status is created or paid)
  /// 2. Updates parcel status to cancelled
  /// 3. Releases held balance back to available
  /// 4. Shows appropriate feedback to user
  Future<void> cancelParcel({
    required String parcelId,
    required String userId,
    required double amount,
    String? reason,
  }) async {
    final currentData = state.data ?? const ParcelData();

    // Show loading state
    emit(
      AsyncLoadingState<ParcelData>(
        data: currentData.copyWith(updatingParcelId: parcelId),
      ),
    );

    try {
      // 1. Update parcel status to cancelled
      final statusResult = await _parcelUseCase.updateParcelStatus(
        parcelId,
        ParcelStatus.cancelled,
      );

      await statusResult.fold(
        (failure) async {
          emit(
            AsyncErrorState<ParcelData>(
              errorMessage: failure.failureMessage,
              data: currentData.copyWith(clearUpdatingParcelId: true),
            ),
          );
          DFoodUtils.showSnackBar(
            'Failed to cancel parcel: ${failure.failureMessage}',
            AppColors.error,
          );
        },
        (cancelledParcel) async {
          // 2. Release held balance back to available
          final releaseResult = await _walletUseCase.releaseBalance(
            userId,
            amount,
            parcelId,
            'parcel_release_$parcelId',
          );

          releaseResult.fold(
            (failure) {
              // Log release failure but parcel is cancelled
              DFoodUtils.showSnackBar(
                'Parcel cancelled! Balance release pending.',
                AppColors.warning,
              );
            },
            (_) {
              DFoodUtils.showSnackBar(
                'Parcel cancelled. Balance returned to available.',
                AppColors.success,
              );
            },
          );

          // 3. Update state with cancelled parcel
          final updatedData = _applyOptimisticUpdate(
            currentData,
            cancelledParcel,
          ).copyWith(clearUpdatingParcelId: true);
          emit(
            LoadedState<ParcelData>(
              data: updatedData,
              lastUpdated: DateTime.now(),
            ),
          );
        },
      );
    } catch (e) {
      emit(
        AsyncErrorState<ParcelData>(
          errorMessage: e.toString(),
          data: currentData.copyWith(clearUpdatingParcelId: true),
        ),
      );
      DFoodUtils.showSnackBar('Error cancelling parcel: $e', AppColors.error);
    }
  }

  @override
  Future<void> close() {
    _connectivityService.dispose();
    return super.close();
  }

  // ==================== Stream Methods ====================

  /// Watches real-time updates for a specific parcel's status.
  ///
  /// Returns a stream that emits [Either<Failure, ParcelEntity>] on each update.
  Stream<Either<Failure, ParcelEntity>> watchParcelStatus(
    String parcelId,
  ) async* {
    try {
      yield* _parcelUseCase.watchParcelStatus(parcelId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  /// Watches real-time updates for all parcels created by a user.
  ///
  /// Returns a stream that emits [Either<Failure, List<ParcelEntity>>] on each update.
  Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(
    String userId,
  ) async* {
    try {
      yield* _parcelUseCase.watchUserParcels(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  /// Watches real-time updates for parcels accepted by a user (as traveler).
  ///
  /// Returns a stream that emits [Either<Failure, List<ParcelEntity>>] on each update.
  Stream<Either<Failure, List<ParcelEntity>>> watchAcceptedParcels(
    String userId,
  ) async* {
    try {
      yield* _parcelUseCase.watchUserAcceptedParcels(userId);
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }

  /// Watches real-time updates for all available parcels (status: created/paid, no traveler).
  ///
  /// Returns a stream that emits [Either<Failure, List<ParcelEntity>>] on each update.
  Stream<Either<Failure, List<ParcelEntity>>> watchAvailableParcels() async* {
    try {
      yield* _parcelUseCase.watchAvailableParcels();
    } catch (e, stackTrace) {
      handleException(Exception(e.toString()), stackTrace);
    }
  }
}
