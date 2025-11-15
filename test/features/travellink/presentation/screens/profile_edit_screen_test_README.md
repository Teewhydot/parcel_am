# ProfileEditScreen Widget Tests

This file contains comprehensive widget tests for the `ProfileEditScreen` component.

## Test Coverage

### 1. Initial State and UI
- **renders correctly with initial data**: Verifies all required UI elements are present (title, fields, buttons)
- **loads existing user data into form fields**: Ensures user's existing displayName and email are pre-populated

### 2. Form Validation
- **validates displayName is not empty**: Tests that empty displayName shows error message
- **validates displayName minimum length**: Tests that displayName must be at least 3 characters
- **validates email is not empty**: Tests that empty email shows error message
- **validates email format**: Tests that invalid email formats are rejected
- **passes validation with valid inputs**: Tests that valid data triggers the save event

### 3. Image Picker Integration
- **displays image picker button**: Verifies the image picker UI is rendered
- **tapping image picker opens camera_alt icon**: Tests that the image picker button shows appropriate icon

### 4. Save Button and Events
- **save button triggers AuthUserProfileUpdateRequested with correct data**: Verifies that the save button dispatches the correct BLoC event with proper data
- **save button is disabled during submission**: Ensures the save button is disabled during loading state

### 5. Loading State
- **displays loading indicator during profile update**: Tests that CircularProgressIndicator is shown during updates
- **disables form inputs during loading**: Ensures all interactive elements are disabled while loading

### 6. Success Message Display
- **displays success snackbar on successful update**: Verifies success SnackBar appears with correct message
- **displays default success message when none provided**: Tests fallback success message

### 7. Error Message Display
- **displays error snackbar on update failure**: Verifies error SnackBar appears with error message
- **displays default error message when none provided**: Tests fallback error message

### 8. Cancel Button Navigation
- **cancel button pops navigation**: Tests that cancel button navigates back
- **cancel button is disabled during loading**: Ensures cancel button is disabled during submission

## Running the Tests

To run these tests, use:

```bash
flutter test test/features/travellink/presentation/screens/profile_edit_screen_test.dart
```

To run with coverage:

```bash
flutter test --coverage test/features/travellink/presentation/screens/profile_edit_screen_test.dart
```

## Dependencies

- `flutter_test`: Flutter testing framework
- `mockito`: Mocking library for AuthBloc
- `bloc_test`: Helper package for testing BLoC components
