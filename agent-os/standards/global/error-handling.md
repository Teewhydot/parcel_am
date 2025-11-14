## Error Handling Best Practices

## User-Friendly Error Messages
- Show clear, actionable messages without technical details: "Unable to load data" not "FirebaseException: code 7"
- Provide next steps: "Check your internet connection and try again"
- Don't expose stack traces or Firebase error codes to users
- Use SnackBar or Dialog for error notifications
- Maintain consistent error message styling across app
- Translate error messages for internationalized apps

## Exception Handling in Dart
- Use try-catch blocks around operations that can fail
- Catch specific exception types: catch (e on FirebaseException)
- Use on keyword for type-specific catches: on FormatException, on NetworkException
- Catch generic Exception last as fallback
- Always log exceptions for debugging: print(), logger, or Firebase Crashlytics
- Don't use empty catch blocks - at minimum log the error
- Use rethrow to preserve stack trace when re-throwing exceptions

## Firebase Error Handling
- Handle FirebaseException with specific error codes
- Common codes: permission-denied, not-found, unavailable, unauthenticated
- Check error.code to provide specific user messages
- Retry on 'unavailable' (network issues), show message on 'permission-denied'
- Log to Firebase Crashlytics: FirebaseCrashlytics.instance.recordError(exception, stackTrace)
- Handle auth errors separately from Firestore errors

## Fail Fast
- Validate preconditions at the start of functions
- Use assert() for development-time checks (removed in release mode)
- Throw ArgumentError for invalid arguments with descriptive messages
- Use require() style checks for required parameters
- Return early from functions when validation fails
- Don't attempt operations with invalid state

## Centralized Error Handling
- Handle errors in BLoC/Cubit, emit error states to UI
- Create error state classes: LoadingError, SubmissionError
- Use BlocListener to show error messages (SnackBars, Dialogs)
- Don't scatter try-catch blocks throughout widgets
- Create error handling utilities or extensions
- Use Result or Either types for explicit success/failure handling

## State-Based Error Display
- Model errors as states in BLoC/Cubit: State.error(String message)
- Display errors conditionally based on state in UI
- Show retry buttons for recoverable errors
- Clear error state after user acknowledges
- Don't block UI indefinitely on errors
- Show error widget/screen for critical failures

## Graceful Degradation
- Continue functioning when non-critical features fail
- Show cached data when network is unavailable
- Disable features gracefully instead of crashing
- Provide fallback UI for failed image loads
- Handle missing optional fields in Firestore documents
- Use default values when data fetch fails

## Network & Connectivity
- Check connectivity before making Firebase calls (connectivity_plus package)
- Show offline indicator when no internet connection
- Queue writes when offline (Firestore does this automatically with offline persistence)
- Retry failed operations with exponential backoff
- Handle timeout errors with user-friendly messages
- Cache data locally for offline access

## Retry Strategies
- Implement exponential backoff for transient failures
- Retry logic: 1s, 2s, 4s, 8s delays
- Set maximum retry attempts (e.g., 3-5 times)
- Only retry operations that are safe to retry (idempotent)
- Show retry button for user-initiated retries
- Don't retry on permanent errors (permission-denied, not-found)

## Resource Cleanup
- Dispose controllers in dispose() method: controller.dispose()
- Cancel StreamSubscriptions: subscription.cancel()
- Close Sinks and StreamControllers: streamController.close()
- Use try-finally for guaranteed cleanup
- Implement proper disposal in StatefulWidgets
- Remove listeners in dispose(): notifier.removeListener(listener)

## Async Error Handling
- Always await async operations or handle Futures properly
- Use try-catch around await calls
- Handle errors in .catchError() for Futures
- Use onError parameter for Stream listeners
- Check mounted before calling setState() in async callbacks
- Handle Future errors at call site, not globally

## Error Logging & Monitoring
- Log errors to console during development: debugPrint()
- Use Firebase Crashlytics for production error tracking
- Log error context: user action, screen, data state
- Don't log sensitive user data (passwords, tokens, etc.)
- Set up error alerts for critical issues
- Review error logs regularly to identify patterns

## Error Widgets
- Use ErrorWidget for custom error displays
- Show friendly error screens for fatal errors
- Include illustration or icon for better UX
- Provide retry button or navigation back to home
- Override ErrorWidget.builder for custom global error widget
- Test error states in development

## Flutter-Specific
- Handle FlutterError with FlutterError.onError hook
- Catch errors in runZonedGuarded for uncaught exceptions
- Use ErrorWidget for widget tree errors
- Handle platform-specific errors (MethodChannel exceptions)
- Test error scenarios with widget tests
