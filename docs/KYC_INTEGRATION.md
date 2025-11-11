# KYC Integration Documentation

## Overview

The KYC (Know Your Customer) system has been fully integrated with the authentication flow. The integration includes:

1. **KycBloc**: Handles KYC submission, status checking, and real-time status updates
2. **AuthBloc Integration**: Automatically syncs KYC status with user profile
3. **UserEntity Enhancement**: Includes `kycStatus` field
4. **Real-time Updates**: Firestore-based stream subscription for instant KYC status changes

## Architecture

### Components

#### 1. KycBloc
**Location**: `lib/features/travellink/presentation/bloc/kyc/`

**Events**:
- `KycSubmitRequested`: Submit new KYC documents
- `KycStatusRequested`: Check current KYC status
- `KycStatusUpdated`: Internal event for real-time updates
- `KycResubmitRequested`: Resubmit after rejection

**States**:
- `KycInitial`: No KYC submitted
- `KycLoading`: Processing submission or checking status
- `KycSubmitted`: KYC submitted and pending review
- `KycApproved`: KYC approved
- `KycRejected`: KYC rejected with reason
- `KycError`: Error during KYC operation

**Usage**:
```dart
// Submit KYC
context.read<KycBloc>().add(KycSubmitRequested(
  fullName: 'John Doe',
  dateOfBirth: '1990-01-01',
  address: '123 Main St',
  idType: 'passport',
  idNumber: 'ABC123',
  frontImagePath: frontImageFile.path,
  backImagePath: backImageFile.path,
  selfieImagePath: selfieFile.path,
));

// Subscribe to status updates
context.read<KycBloc>().subscribeToKycStatus(userId);

// Check status
context.read<KycBloc>().add(const KycStatusRequested());
```

#### 2. AuthBloc KYC Integration
**Location**: `lib/features/travellink/presentation/bloc/auth/auth_bloc.dart`

**New Event**:
- `AuthKycStatusUpdated`: Updates user's KYC status in AuthBloc

**Features**:
- Automatic KYC status stream subscription after login/register
- Unsubscribes on logout
- Updates `UserEntity.kycStatus` in real-time
- Persists across authentication state changes

#### 3. UserEntity
**Location**: `lib/features/travellink/domain/entities/user_entity.dart`

**New Field**:
```dart
final String kycStatus; // Default: 'not_submitted'
```

**Possible Values**:
- `'not_submitted'`: User hasn't submitted KYC
- `'pending'`: KYC submitted, awaiting review
- `'approved'`: KYC approved, full access
- `'rejected'`: KYC rejected, can resubmit

#### 4. Data Source Updates

**AuthRemoteDataSource** (`lib/features/travellink/data/datasources/auth_remote_data_source.dart`):
- Added `syncKycStatus()` method
- New `_mapFirebaseUserToModelWithKyc()` helper to fetch KYC status from Firestore
- Automatically creates user document with `kycStatus` on registration
- Updates all user fetch methods to include KYC status

**KycRemoteDataSource** (`lib/features/travellink/data/datasources/kyc_remote_data_source.dart`):
- `submitKyc()`: Uploads images to Firebase Storage and creates Firestore document
- `getKycStatus()`: Fetches current status from Firestore
- `watchKycStatus()`: Returns real-time stream of status changes

## Data Flow

### 1. Registration/Login Flow
```
User Login/Register
    ↓
AuthBloc retrieves user
    ↓
User includes kycStatus from Firestore
    ↓
AuthBloc subscribes to KYC status stream
    ↓
Real-time updates via AuthKycStatusUpdated event
```

### 2. KYC Submission Flow
```
User submits KYC via KycBloc
    ↓
Images uploaded to Firebase Storage
    ↓
KYC data saved to Firestore (kyc_submissions collection)
    ↓
User document updated with kycStatus: 'pending'
    ↓
Stream emits new status
    ↓
Both KycBloc and AuthBloc receive update
```

### 3. Status Change Flow
```
Admin updates KYC status in Firestore
    ↓
Firestore triggers stream event
    ↓
watchKycStatus() emits new status
    ↓
KycBloc: KycStatusUpdated event
    ↓
AuthBloc: AuthKycStatusUpdated event
    ↓
UI automatically updates
```

## Firebase Schema

### users Collection
```json
{
  "userId": "user123",
  "displayName": "John Doe",
  "email": "john@example.com",
  "kycStatus": "pending",
  "createdAt": "timestamp"
}
```

### kyc_submissions Collection
```json
{
  "userId": "user123",
  "fullName": "John Doe",
  "dateOfBirth": "1990-01-01",
  "address": "123 Main St",
  "idType": "passport",
  "idNumber": "ABC123",
  "frontImageUrl": "gs://bucket/kyc/user123/front",
  "backImageUrl": "gs://bucket/kyc/user123/back",
  "selfieImageUrl": "gs://bucket/kyc/user123/selfie",
  "status": "pending",
  "submittedAt": "timestamp"
}
```

## Dependency Injection

All components are registered in `lib/injection_container.dart`:

```dart
// KYC BLoC
sl.registerFactory(() => KycBloc(
  submitKycUseCase: sl(),
  getKycStatusUseCase: sl(),
  watchKycStatusUseCase: sl(),
));

// Use Cases
sl.registerLazySingleton(() => SubmitKycUseCase(sl()));
sl.registerLazySingleton(() => GetKycStatusUseCase(sl()));
sl.registerLazySingleton(() => WatchKycStatusUseCase(sl()));

// Repository & Data Source
sl.registerLazySingleton<KycRepository>(() => KycRepositoryImpl(
  remoteDataSource: sl(),
));
sl.registerLazySingleton<KycRemoteDataSource>(() => KycRemoteDataSourceImpl(
  firestore: sl(),
  storage: sl(),
));

// AuthBloc now includes WatchKycStatusUseCase
sl.registerFactory(() => AuthBloc(
  // ... other use cases
  watchKycStatusUseCase: sl(),
));
```

## UI Integration Example

```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BaseState<AuthData>>(
      builder: (context, state) {
        if (state is LoadedState<AuthData>) {
          final user = state.data?.user;
          final kycStatus = user?.kycStatus ?? 'not_submitted';
          
          return Column(
            children: [
              Text('KYC Status: $kycStatus'),
              if (kycStatus == 'not_submitted')
                ElevatedButton(
                  onPressed: () => Navigator.push(/* KYC form */),
                  child: Text('Submit KYC'),
                ),
              if (kycStatus == 'pending')
                Text('KYC under review'),
              if (kycStatus == 'approved')
                Icon(Icons.verified, color: Colors.green),
              if (kycStatus == 'rejected')
                ElevatedButton(
                  onPressed: () => Navigator.push(/* KYC resubmit */),
                  child: Text('Resubmit KYC'),
                ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## Testing

Tests are included for both BLoCs:

- `test/features/travellink/presentation/bloc/kyc_bloc_test.dart`: Tests KycBloc functionality
- `test/features/travellink/presentation/bloc/auth_bloc_kyc_test.dart`: Tests AuthBloc KYC integration

Run tests:
```bash
flutter test test/features/travellink/presentation/bloc/kyc_bloc_test.dart
flutter test test/features/travellink/presentation/bloc/auth_bloc_kyc_test.dart
```

## Security Considerations

1. **Image Storage**: Images stored in Firebase Storage with user-specific paths
2. **Access Control**: Firestore rules should restrict KYC status updates to admins only
3. **Data Validation**: All inputs validated before submission
4. **Stream Security**: Users can only watch their own KYC status

## Recommended Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId 
                    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['kycStatus']);
    }
    
    match /kyc_submissions/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if false; // Only admins via Admin SDK
    }
  }
}
```

## Future Enhancements

1. Add expiry dates for KYC documents
2. Support multiple document types
3. Add audit trail for status changes
4. Implement OCR for automatic data extraction
5. Add notifications for status changes
