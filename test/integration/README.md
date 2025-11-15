# Integration Tests

This directory contains integration tests that validate complete workflows across multiple layers of the application.

## Profile Update Integration Test

**File:** `profile_update_integration_test.dart`

### Overview

Comprehensive integration test suite for the complete profile update workflow, including:
- Profile photo selection and upload to Firebase Storage
- Firestore document updates with new profile data
- AuthBloc state management and transitions
- ProfileScreen data refresh with updated information
- Error handling for network, storage, and Firestore failures

### Test Coverage

#### 1. Complete Profile Update Workflow
- **Test:** Complete profile update workflow - photo upload to Storage, Firestore update, AuthBloc refresh
- **Validates:** End-to-end profile update with photo URL
- **Mocks:** Firebase Auth, Firestore, Storage
- **Verifies:** 
  - Photo upload simulation
  - Firestore document update
  - AuthBloc state transitions (Loading → Loaded)
  - Profile data correctly updated in state

#### 2. Network Error Handling
- **Test:** Profile update fails with network error
- **Validates:** Proper error handling when network is unavailable
- **Verifies:** Network connectivity check before update

#### 3. Profile Screen Refresh
- **Test:** Profile screen refresh after successful update
- **Validates:** UI refresh with new profile data
- **Verifies:**
  - Display name update
  - Email update
  - Additional data fields (bio, phone) update
  - State transitions

#### 4. Race Condition Handling
- **Test:** Multiple rapid profile updates - handles race conditions
- **Validates:** Concurrent update handling
- **Verifies:** Last write wins, no state corruption

#### 5. Data Preservation
- **Test:** Profile update preserves existing user data
- **Validates:** Partial updates don't overwrite unrelated fields
- **Verifies:**
  - Display name updated
  - Other fields (email, rating, deliveries) preserved
  - Additional data preserved

#### 6. Data Merging
- **Test:** Profile update merges additionalData correctly
- **Validates:** New additional data merged with existing
- **Verifies:**
  - New fields added
  - Updated fields overwritten
  - Existing unmodified fields preserved

#### 7. KYC Status Update
- **Test:** KYC status update along with profile update
- **Validates:** KYC status changes reflected in profile
- **Verifies:** KYC status transitions (notStarted → pending)

#### 8. Storage Upload Failure
- **Test:** Simulate storage upload failure scenario
- **Validates:** Firebase Storage error handling
- **Verifies:** FirebaseException thrown with correct error code

#### 9. Firestore Update Failure
- **Test:** Simulate Firestore update failure scenario
- **Validates:** Firestore permission error handling
- **Verifies:** FirebaseException with permission-denied code

#### 10. Photo Selection Simulation
- **Test:** Complete workflow - photo selection simulation
- **Validates:** Image picker integration
- **Verifies:** XFile path handling

#### 11. Storage URL Generation
- **Test:** Storage URL generation pattern
- **Validates:** Proper Storage URL format
- **Verifies:** URL contains user ID and domain

#### 12. State Transitions
- **Test:** User profile state transitions
- **Validates:** AuthBloc state machine
- **Verifies:** Initial → Loading → Loaded → Success transitions

#### 13. Null User Handling
- **Test:** Error handling for null user during update
- **Validates:** Update attempts with no authenticated user
- **Verifies:** Proper state when user is null

#### 14. Photo URL in Additional Data
- **Test:** Profile photo URL update in additionalData
- **Validates:** Photo URL storage in additional data
- **Verifies:** Photo URL and timestamp stored correctly

#### 15. Concurrent Updates
- **Test:** Concurrent profile updates - last write wins
- **Validates:** Multiple simultaneous updates
- **Verifies:** Final state reflects last update

### Running the Tests

```bash
# Run all integration tests
flutter test test/integration/

# Run profile update integration tests only
flutter test test/integration/profile_update_integration_test.dart

# Run with verbose output
flutter test test/integration/profile_update_integration_test.dart --verbose
```

### Mocked Dependencies

- **FirebaseAuth:** User authentication state
- **FirebaseFirestore:** User document storage
- **FirebaseStorage:** Profile photo storage
- **AuthRemoteDataSource:** Remote data operations
- **NetworkInfo:** Network connectivity status
- **ImagePicker:** Photo selection (conceptual)

### Architecture

The tests follow Clean Architecture principles:
- **Data Layer:** Mocked AuthRemoteDataSource
- **Domain Layer:** UserEntity models
- **Presentation Layer:** AuthBloc state management

### Key Assertions

1. **State Transitions:** Verifies correct BLoC state flow
2. **Data Integrity:** Ensures data preservation and merging
3. **Error Handling:** Validates proper error states
4. **Concurrency:** Tests race condition handling
5. **Integration:** Validates cross-layer communication

### Future Enhancements

- Add widget tests for ProfileScreen UI
- Test actual Firebase Storage upload with test buckets
- Add performance benchmarks for profile updates
- Test offline mode and sync behavior
- Add accessibility tests for profile UI
