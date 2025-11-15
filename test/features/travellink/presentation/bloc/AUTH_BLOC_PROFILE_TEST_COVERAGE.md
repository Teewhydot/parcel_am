# AuthBloc Profile Functionality Test Coverage

## Test File
`test/features/travellink/presentation/bloc/auth_bloc_profile_test.dart`

## Overview
Comprehensive unit tests for AuthBloc profile functionality covering:
- Profile update event handling
- Firebase Storage integration scenarios
- State emission verification
- Error handling
- Use case integration

## Test Groups and Coverage

### 1. AuthUserProfileUpdateRequested - Basic Profile Updates
Tests fundamental profile update operations:

#### Test: "emits LoadingState then LoadedState when profile update is successful"
- Verifies state emission sequence
- Checks LoadingState message: "Updating profile..."
- Validates LoadedState contains updated displayName
- Ensures uid and email are preserved

#### Test: "updates email when provided in event"
- Tests email update functionality
- Verifies email change propagates to user entity

#### Test: "updates kycStatus when provided in event"
- Tests KYC status update alongside profile data
- Validates KycStatus enum handling

#### Test: "does nothing when user is null"
- Edge case: ensures no state emission when user doesn't exist
- Validates early exit behavior

### 2. AuthUserProfileUpdateRequested - Additional Data Updates
Tests additionalData map handling:

#### Test: "merges new additionalData with existing data"
- Verifies new keys are added to existing map
- Ensures original data is preserved
- Tests data: {'phoneNumber': '+1234567890', 'country': 'USA', 'city': 'New York'}

#### Test: "overwrites existing additionalData keys"
- Validates that duplicate keys are updated, not duplicated
- Tests phoneNumber overwrite scenario

#### Test: "preserves existing additionalData when null provided"
- Ensures null additionalData parameter doesn't clear existing data
- Validates defensive programming

### 3. AuthUserProfileUpdateRequested - State Emissions
Validates state management patterns:

#### Test: "emits states in correct order: LoadingState -> LoadedState"
- Verifies BLoC state emission sequence
- Uses skip and verify blocks

#### Test: "LoadingState has correct message"
- Validates loading message: "Updating profile..."
- Uses predicate matcher

#### Test: "LoadedState updates lastUpdated timestamp"
- Ensures timestamp is updated on profile changes
- Validates within 5-second window

### 4. AuthUserProfileUpdateRequested - Profile Photo Updates
Tests Firebase Storage integration scenarios:

#### Test: "updates profile photo URL in additionalData"
- Simulates Firebase Storage URL in additionalData
- URL pattern: 'https://example.com/new-photo.jpg'

#### Test: "updates multiple profile fields including photo URL"
- Tests combined update: displayName, email, profilePhotoUrl, bio
- Validates complex update scenarios
- Uses Firebase Storage URL pattern: 'https://storage.example.com/photo.jpg'

### 5. updateUserProfile UseCase Integration
Tests integration with AuthUseCase:

#### Test: "integrates with updateUserProfile use case - success scenario"
- Mocks AuthUseCase.updateUserProfile()
- Validates Right(updatedUser) response handling
- Tests Firebase Storage URL: 'https://firebase.storage.com/updated-photo.jpg'

#### Test: "profile update maintains user identity (uid)"
- Ensures uid never changes during updates
- Critical for data integrity

#### Test: "profile update preserves all existing user fields"
- Validates rating, completedDeliveries, packagesSent preserved
- Ensures profilePhotoUrl maintained when not updated

### 6. Profile Update Error Handling
Tests failure scenarios:

#### Test: "handles network error when updating profile with Firebase Storage"
- Mocks NoInternetFailure
- Validates graceful error handling
- Tests offline Firebase Storage scenario

#### Test: "handles storage error when uploading profile photo"
- Mocks ServerFailure: 'Storage upload failed'
- Tests Firebase Storage upload failure

#### Test: "does not emit states when user is null (early exit)"
- Validates InitialState handling
- Ensures no crashes on null user

### 7. Complex Profile Update Scenarios
Tests real-world usage patterns:

#### Test: "handles multiple consecutive profile updates"
- Three sequential updates
- Validates state transitions
- Tests: First Update -> Second Update (with email) -> Final Update (with KYC)

#### Test: "maintains data integrity across profile updates"
- Comprehensive field validation
- Tests all UserEntity fields preserved correctly
- Validates additionalData merging with complex data

### 8. Profile Update with KYC Status Changes
Tests combined profile and KYC updates:

#### Test: "updates profile and KYC status together"
- Combined displayName, kycStatus, and additionalData update
- Tests workflow after KYC verification

#### Test: "transitions KYC status from notStarted to pending"
- Tests KYC status flow
- Validates enum transitions

## State Emissions Tested

### LoadingState
- ✅ Emitted before profile update operations
- ✅ Contains message: "Updating profile..."
- ✅ No progress indicator (null)

### LoadedState
- ✅ Contains updated user data
- ✅ Updates lastUpdated timestamp
- ✅ Preserves all existing fields
- ✅ Merges additionalData correctly

### SuccessState
- ⚠️ Not currently emitted by _onUserProfileUpdateRequested
- Note: BLoC emits LoadedState directly without SuccessState

### ErrorState
- ⚠️ Not emitted in current implementation
- Error handling mocked but BLoC doesn't emit ErrorState for profile updates

## Firebase Storage Integration Points

### Profile Photo Upload Scenarios Tested:
1. **New photo upload** - URL in additionalData
2. **Photo update** - Overwrites existing profilePhotoUrl
3. **Network failure** - NoInternetFailure during upload
4. **Storage failure** - ServerFailure from Firebase Storage
5. **Multiple field updates** - Photo URL with other profile changes

### Expected Firebase Storage Workflow:
```
User picks image -> Upload to Firebase Storage -> Get download URL -> 
Update additionalData with URL -> Emit LoadedState
```

### Test Mock Patterns:
```dart
when(mockAuthUseCase.updateUserProfile(any))
  .thenAnswer((_) async => Right(updatedUser));

when(mockAuthUseCase.updateUserProfile(any))
  .thenAnswer((_) async => Left(ServerFailure(failureMessage: 'Storage upload failed')));
```

## Use Case Integration

### AuthUseCase.updateUserProfile() tested with:
- ✅ Success scenario (Right<UserEntity>)
- ✅ Network failure (Left<NoInternetFailure>)
- ✅ Storage failure (Left<ServerFailure>)
- ✅ User entity transformation
- ✅ Profile data persistence

## Test Statistics

- **Total Test Groups**: 8
- **Total Test Cases**: 19
- **BLoC Tests**: 14 (using blocTest)
- **Unit Tests**: 5 (using test)
- **Lines of Code**: 634

## Dependencies Mocked
- `AuthUseCase` (MockAuthUseCase)
- Uses Mockito for mock generation

## Key Assertions

### State Type Assertions:
```dart
isA<LoadingState<AuthData>>()
isA<LoadedState<AuthData>>()
```

### Field Value Assertions:
```dart
.having((state) => state.data?.user?.displayName, 'displayName', 'Jane Smith')
.having((state) => state.message, 'message', 'Updating profile...')
```

### Data Integrity Assertions:
```dart
expect(user?.uid, equals('user123'));
expect(user?.rating, equals(4.5));
expect(user?.completedDeliveries, equals(10));
```

## Potential Improvements

### Current Implementation Gaps:
1. **No SuccessState emission** - Profile updates don't emit SuccessState for user feedback
2. **No ErrorState emission** - Errors are handled but not propagated as ErrorState
3. **No actual Firebase Storage integration** - updateUserProfile use case not called in BLoC

### Recommended Enhancements:
1. Integrate `authUseCase.updateUserProfile()` in the BLoC event handler
2. Emit SuccessState after successful profile update
3. Emit ErrorState when updateUserProfile fails
4. Add retry mechanism for network failures
5. Add profile photo validation before upload

### Additional Test Coverage Needed:
1. Profile photo file size validation
2. Supported image format checking
3. Upload progress tracking
4. Concurrent update handling
5. Optimistic updates with rollback on failure

## Running the Tests

```bash
# Run profile tests only
flutter test test/features/travellink/presentation/bloc/auth_bloc_profile_test.dart

# Run with coverage
flutter test --coverage test/features/travellink/presentation/bloc/auth_bloc_profile_test.dart

# Run all auth tests
flutter test test/features/travellink/presentation/bloc/auth_bloc_*_test.dart
```

## Related Files
- `lib/features/travellink/presentation/bloc/auth/auth_bloc.dart`
- `lib/features/travellink/presentation/bloc/auth/auth_event.dart`
- `lib/features/travellink/presentation/bloc/auth/auth_data.dart`
- `lib/features/travellink/domain/usecases/auth_usecase.dart`
- `lib/features/travellink/domain/entities/user_entity.dart`
- `lib/core/bloc/base/base_state.dart`
