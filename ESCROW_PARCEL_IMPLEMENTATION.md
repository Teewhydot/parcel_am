# Escrow and Parcel Data Layer Implementation

## Overview
This implementation provides real-time Firestore streaming capabilities for Escrow and Parcel management with Clean Architecture and BLoC patterns.

## Files Created

### Domain Layer (Entities & Repositories)

1. **lib/features/travellink/domain/entities/escrow_entity.dart**
   - `EscrowEntity` class with Equatable
   - `EscrowStatus` enum (pending, held, released, cancelled, refunded, disputed)
   - Properties: id, parcelId, senderId, travelerId, amount, currency, status, timestamps, metadata

2. **lib/features/travellink/domain/entities/parcel_entity.dart**
   - `ParcelEntity` class with Equatable
   - `ParcelStatus` enum (pending, accepted, inTransit, delivered, cancelled, disputed)
   - `ParcelType` enum (document, electronics, clothing, food, medication, other)
   - Properties: id, senderId, travelerId, title, description, type, weight, dimensions, locations, dates, amount, currency, status, escrowId, metadata

3. **lib/features/travellink/domain/repositories/escrow_repository.dart**
   - Abstract repository interface
   - Methods:
     - `Stream<Either<Failure, EscrowEntity>> watchEscrowStatus(String escrowId)`
     - `Stream<Either<Failure, EscrowEntity?>> watchEscrowByParcel(String parcelId)`
     - `Future<Either<Failure, EscrowEntity>> createEscrow(...)`
     - `Future<Either<Failure, EscrowEntity>> holdEscrow(String escrowId)`
     - `Future<Either<Failure, EscrowEntity>> releaseEscrow(String escrowId)`
     - `Future<Either<Failure, EscrowEntity>> cancelEscrow(String escrowId)`
     - `Future<Either<Failure, EscrowEntity>> getEscrow(String escrowId)`

4. **lib/features/travellink/domain/repositories/parcel_repository.dart**
   - Abstract repository interface
   - Methods:
     - `Stream<Either<Failure, ParcelEntity>> watchParcelStatus(String parcelId)`
     - `Stream<Either<Failure, List<ParcelEntity>>> watchUserParcels(String userId)`
     - `Stream<Either<Failure, List<ParcelEntity>>> watchParcelsByStatus(ParcelStatus status)`
     - `Future<Either<Failure, ParcelEntity>> createParcel(ParcelEntity parcel)`
     - `Future<Either<Failure, ParcelEntity>> updateParcel(String parcelId, Map<String, dynamic> data)`
     - `Future<Either<Failure, ParcelEntity>> updateParcelStatus(String parcelId, ParcelStatus status)`
     - `Future<Either<Failure, ParcelEntity>> assignTraveler(String parcelId, String travelerId)`
     - `Future<Either<Failure, ParcelEntity>> getParcel(String parcelId)`
     - `Future<Either<Failure, List<ParcelEntity>>> getParcelsByUser(String userId)`

### Data Layer (Models, Data Sources, Repository Implementations)

5. **lib/features/travellink/data/models/escrow_model.dart**
   - `EscrowModel` class
   - `fromFirestore(DocumentSnapshot doc)` factory - Firestore deserialization
   - `fromEntity(EscrowEntity entity)` factory - Convert from domain entity
   - `toJson()` method - Firestore serialization
   - `toEntity()` method - Convert to domain entity
   - `copyWith()` method
   - Status enum conversion helpers

6. **lib/features/travellink/data/models/parcel_model.dart**
   - `ParcelModel` class
   - `fromFirestore(DocumentSnapshot doc)` factory - Firestore deserialization
   - `fromEntity(ParcelEntity entity)` factory - Convert from domain entity
   - `toJson()` method - Firestore serialization
   - `toEntity()` method - Convert to domain entity
   - `copyWith()` method
   - Status and type enum conversion helpers

7. **lib/features/travellink/data/datasources/escrow_remote_data_source.dart**
   - `EscrowRemoteDataSource` abstract class
   - `EscrowRemoteDataSourceImpl` implementation
   - **Stream Methods:**
     - `Stream<EscrowModel> watchEscrowStatus(String escrowId)` - Real-time escrow status monitoring
     - `Stream<EscrowModel?> watchEscrowByParcel(String parcelId)` - Watch escrow by parcel ID
   - **Future Methods:**
     - `Future<EscrowModel> createEscrow(...)` - Create new escrow
     - `Future<EscrowModel> updateEscrowStatus(String escrowId, EscrowStatus status)` - Update status
     - `Future<EscrowModel> holdEscrow(String escrowId)` - Hold funds in escrow
     - `Future<EscrowModel> releaseEscrow(String escrowId)` - Release funds from escrow
     - `Future<EscrowModel> cancelEscrow(String escrowId)` - Cancel escrow
     - `Future<EscrowModel> getEscrow(String escrowId)` - Get escrow once

8. **lib/features/travellink/data/datasources/parcel_remote_data_source.dart**
   - `ParcelRemoteDataSource` abstract class
   - `ParcelRemoteDataSourceImpl` implementation
   - **Stream Methods:**
     - `Stream<ParcelModel> watchParcelStatus(String parcelId)` - Real-time parcel status monitoring
     - `Stream<List<ParcelModel>> watchUserParcels(String userId)` - Watch all user's parcels
     - `Stream<List<ParcelModel>> watchParcelsByStatus(ParcelStatus status)` - Watch parcels by status
   - **Future Methods:**
     - `Future<ParcelModel> createParcel(ParcelModel parcel)` - Create new parcel
     - `Future<ParcelModel> updateParcel(String parcelId, Map<String, dynamic> data)` - Update parcel
     - `Future<ParcelModel> updateParcelStatus(String parcelId, ParcelStatus status)` - Update status
     - `Future<ParcelModel> assignTraveler(String parcelId, String travelerId)` - Assign traveler
     - `Future<ParcelModel> getParcel(String parcelId)` - Get parcel once
     - `Future<List<ParcelModel>> getParcelsByUser(String userId)` - Get user parcels once

9. **lib/features/travellink/data/repositories/escrow_repository_impl.dart**
   - `EscrowRepositoryImpl` implements `EscrowRepository`
   - Converts data source streams to `Either<Failure, T>` streams
   - Handles network connectivity checks for mutations
   - Exception handling and conversion to appropriate Failures
   - All repository methods wrap data source calls with error handling

10. **lib/features/travellink/data/repositories/parcel_repository_impl.dart**
    - `ParcelRepositoryImpl` implements `ParcelRepository`
    - Converts data source streams to `Either<Failure, T>` streams
    - Handles network connectivity checks for mutations
    - Exception handling and conversion to appropriate Failures
    - All repository methods wrap data source calls with error handling

### Test Files

11. **test/features/travellink/data/models/escrow_model_test.dart**
    - Tests for `EscrowModel` entity conversion
    - Tests fromEntity and toEntity methods

12. **test/features/travellink/data/models/parcel_model_test.dart**
    - Tests for `ParcelModel` entity conversion
    - Tests fromEntity and toEntity methods

## Key Features

### Real-Time Firestore Streams
- All watch methods return Dart streams that automatically update when Firestore data changes
- Streams are converted to `Either<Failure, T>` format in repositories for error handling
- Firestore snapshots are listened to continuously

### Error Handling
- All operations wrap exceptions into typed `Failure` objects
- Stream errors are yielded as `Left(Failure)` values
- Future operations check network connectivity before execution
- Graceful handling of ServerException, NoInternetException, etc.

### Clean Architecture Compliance
- Clear separation between domain, data, and presentation layers
- Entities in domain layer (no external dependencies)
- Models in data layer (Firestore-specific)
- Repository interfaces in domain, implementations in data
- Use of Either<Failure, T> for functional error handling

### Dependency Injection Ready
- Data sources expect FirebaseFirestore injection
- Repositories use GetIt for data source and network info injection
- Abstract interfaces allow easy mocking for tests

## Firestore Collections Structure

### Escrows Collection (`escrows`)
```
{
  parcelId: string
  senderId: string
  travelerId: string
  amount: number
  currency: string
  status: string (pending|held|released|cancelled|refunded|disputed)
  createdAt: timestamp
  heldAt?: timestamp
  releasedAt?: timestamp
  expiresAt?: timestamp
  releaseCondition?: string
  metadata: map
}
```

### Parcels Collection (`parcels`)
```
{
  senderId: string
  travelerId?: string
  title: string
  description: string
  type: string (document|electronics|clothing|food|medication|other)
  weight: number
  dimensions: map<string, string>
  fromLocation: string
  toLocation: string
  requestedDeliveryDate: timestamp
  offeredAmount: number
  currency: string
  status: string (pending|accepted|inTransit|delivered|cancelled|disputed)
  escrowId?: string
  createdAt: timestamp
  acceptedAt?: timestamp
  deliveredAt?: timestamp
  metadata: map
}
```

## Usage Examples

### Watching Escrow Status (Real-time)
```dart
final escrowRepository = GetIt.instance<EscrowRepository>();

escrowRepository.watchEscrowStatus(escrowId).listen((either) {
  either.fold(
    (failure) => print('Error: ${failure.failureMessage}'),
    (escrow) => print('Escrow status: ${escrow.status}'),
  );
});
```

### Watching User Parcels (Real-time)
```dart
final parcelRepository = GetIt.instance<ParcelRepository>();

parcelRepository.watchUserParcels(userId).listen((either) {
  either.fold(
    (failure) => print('Error: ${failure.failureMessage}'),
    (parcels) => print('Found ${parcels.length} parcels'),
  );
});
```

### Creating Escrow
```dart
final result = await escrowRepository.createEscrow(
  parcelId,
  senderId,
  travelerId,
  amount,
  currency,
);

result.fold(
  (failure) => print('Failed: ${failure.failureMessage}'),
  (escrow) => print('Created escrow: ${escrow.id}'),
);
```

## Next Steps

To complete the integration:

1. **Register dependencies** in `lib/injection_container.dart`:
```dart
// Data sources
sl.registerLazySingleton<EscrowRemoteDataSource>(
  () => EscrowRemoteDataSourceImpl(firestore: sl()),
);
sl.registerLazySingleton<ParcelRemoteDataSource>(
  () => ParcelRemoteDataSourceImpl(firestore: sl()),
);

// Repositories
sl.registerLazySingleton<EscrowRepository>(
  () => EscrowRepositoryImpl(),
);
sl.registerLazySingleton<ParcelRepository>(
  () => ParcelRepositoryImpl(),
);
```

2. **Create use cases** in domain layer for business logic

3. **Create BLoCs** in presentation layer for state management

4. **Build UI screens** to consume the streams

## Architecture Benefits

- **Real-time updates**: Firestore snapshots automatically propagate changes
- **Type safety**: Strong typing throughout with enums and entities
- **Testability**: Abstract interfaces allow easy mocking
- **Error handling**: Functional error handling with Either monad
- **Scalability**: Clean Architecture allows independent layer evolution
- **Maintainability**: Clear separation of concerns
