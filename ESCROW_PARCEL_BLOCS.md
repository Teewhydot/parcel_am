# EscrowBloc and ParcelBloc Implementation

## Overview
Created complete EscrowBloc and ParcelBloc with real-time stream subscriptions for Firestore changes.

## Files Created

### Domain Layer
- `lib/features/travellink/domain/entities/escrow_entity.dart` - EscrowEntity with EscrowStatus enum
- `lib/features/travellink/domain/entities/parcel_entity.dart` - ParcelEntity with ParcelStatus enum, LocationEntity, PaymentEntity, TrackingEventEntity
- `lib/features/travellink/domain/repositories/escrow_repository.dart` - EscrowRepository interface
- `lib/features/travellink/domain/repositories/parcel_repository.dart` - ParcelRepository interface
- `lib/features/travellink/domain/usecases/escrow_usecase.dart` - EscrowUseCase
- `lib/features/travellink/domain/usecases/parcel_usecase.dart` - ParcelUseCase

### Data Layer
- `lib/features/travellink/data/models/escrow_model.dart` - EscrowModel with Firestore serialization
- `lib/features/travellink/data/models/parcel_model.dart` - ParcelModel with Firestore serialization
- `lib/features/travellink/data/datasources/escrow_remote_data_source.dart` - Escrow Firestore operations
- `lib/features/travellink/data/datasources/parcel_remote_data_source.dart` - Parcel Firestore operations
- `lib/features/travellink/data/repositories/escrow_repository_impl.dart` - EscrowRepository implementation
- `lib/features/travellink/data/repositories/parcel_repository_impl.dart` - ParcelRepository implementation

### Presentation Layer
- `lib/features/travellink/presentation/bloc/escrow/escrow_event.dart` - Escrow events
- `lib/features/travellink/presentation/bloc/escrow/escrow_state.dart` - Escrow state data
- `lib/features/travellink/presentation/bloc/escrow/escrow_bloc.dart` - EscrowBloc with real-time subscriptions
- `lib/features/travellink/presentation/bloc/parcel/parcel_event.dart` - Parcel events
- `lib/features/travellink/presentation/bloc/parcel/parcel_state.dart` - Parcel state data
- `lib/features/travellink/presentation/bloc/parcel/parcel_bloc.dart` - ParcelBloc with real-time subscriptions

### Dependency Injection
- Updated `lib/injection_container.dart` with all dependencies

## EscrowBloc Features

### Events
- `EscrowCreateRequested` - Create new escrow
- `EscrowHoldRequested` - Hold escrow funds
- `EscrowReleaseRequested` - Release escrow funds
- `EscrowCancelRequested` - Cancel escrow with reason
- `EscrowWatchRequested` - Start watching escrow status
- `EscrowStatusUpdated` - Internal event for real-time updates
- `EscrowLoadUserEscrows` - Load all user escrows

### Real-time Subscriptions
- `_escrowStatusSubscription` - StreamSubscription for watchEscrowStatus
- Automatically emits `EscrowStatusUpdated` events on Firestore changes
- Proper cleanup in `close()` method

### Lifecycle Management
- StreamSubscription properly canceled in `close()`
- Automatic watch setup after escrow creation
- Error handling with AsyncErrorState

## ParcelBloc Features

### Events
- `ParcelCreateRequested` - Create new parcel
- `ParcelUpdateStatusRequested` - Update parcel status
- `ParcelWatchRequested` - Watch single parcel status
- `ParcelWatchUserParcelsRequested` - Watch all user parcels
- `ParcelStatusUpdated` - Internal event for single parcel updates
- `ParcelListUpdated` - Internal event for parcel list updates
- `ParcelLoadRequested` - Load single parcel
- `ParcelLoadUserParcels` - Load all user parcels

### Real-time Subscriptions
- `_parcelStatusSubscription` - StreamSubscription for watchParcelStatus
- `_userParcelsSubscription` - StreamSubscription for watchUserParcels
- Automatically emits state updates on Firestore changes
- Proper cleanup in `close()` method

### Lifecycle Management
- Both StreamSubscriptions properly canceled in `close()`
- Automatic watch setup after parcel creation/loading
- Separate streams for single parcel and parcel list

## Dependency Injection Setup

All dependencies registered in `injection_container.dart`:
- Data Sources (EscrowRemoteDataSource, ParcelRemoteDataSource)
- Repositories (EscrowRepository, ParcelRepository)
- Use Cases (EscrowUseCase, ParcelUseCase)
- BLoCs (EscrowBloc as factory, ParcelBloc as factory)

## Usage Example

```dart
// Get BLoC from DI container
final escrowBloc = sl<EscrowBloc>();
final parcelBloc = sl<ParcelBloc>();

// Create escrow with real-time watching
escrowBloc.add(EscrowCreateRequested(
  walletId: 'wallet_123',
  userId: 'user_456',
  amount: 100.0,
  referenceId: 'parcel_789',
  referenceType: 'parcel',
));

// Watch user parcels in real-time
parcelBloc.add(ParcelLoadUserParcels('user_456'));

// Listen to state changes
escrowBloc.stream.listen((state) {
  if (state is LoadedState<EscrowData>) {
    // Handle escrow updates from Firestore
  }
});
```

## Architecture
- Clean Architecture with separation of concerns
- BLoC pattern for state management
- StreamSubscription management for real-time updates
- Proper resource cleanup
- Error handling with Either<Failure, T>
