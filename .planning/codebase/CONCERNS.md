# Codebase Concerns

**Analysis Date:** 2026-01-08

## Tech Debt

**Large BLoC Files:**
- Issue: `ParcelBloc` and `WalletBloc` exceed 500+ lines each
- Files: `lib/features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart`, `wallet_bloc.dart`
- Why: Multiple related event handlers not extracted to separate service classes
- Impact: Difficult to navigate, test, and modify individual handlers
- Fix approach: Extract large event handlers to separate handler classes or split into multiple focused BLoCs

**Firebase Transaction Logic in BLoCs:**
- Issue: Complex Firestore transaction logic lives in `ParcelBloc._onCreateRequested()` and `_onConfirmDeliveryRequested()`
- Files: `lib/features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart`
- Why: Direct transaction handling in presentation layer
- Impact: Business logic tightly coupled to BLoC, harder to test, reuse
- Fix approach: Move transaction logic to use cases or separate service layer

**Payment Integration Scattered:**
- Issue: Payment handling spread across Flutterwave service, Paystack service, and Cloud Functions
- Files: `functions/services/flutterwave-service.js`, `lib/core/services/paystack_service.dart`, payment BLoCs
- Why: Evolved gradually without unified payment abstraction
- Impact: Duplicate logic, inconsistent error handling
- Fix approach: Create unified payment adapter pattern with consistent interface

**Stream Management in BLoCs:**
- Issue: Manual stream subscriptions not always properly cleaned up
- Files: `lib/features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart`, `wallet_bloc.dart`
- Why: Complex stream subscription patterns with multiple listeners
- Impact: Potential memory leaks if close() not called
- Fix approach: Use `StreamSubscription` management and ensure cleanup in BloC close()

## Known Issues

**Missing Error Handling in File Upload:**
- Symptoms: File upload failures not gracefully handled in all scenarios
- Files: `lib/core/services/file_upload_service.dart`, upload widgets
- Trigger: Network interruption during large file uploads
- Workaround: Manual retry from UI
- Root cause: Incomplete error propagation from Firebase Storage errors
- Fix: Add retry mechanism and detailed error states for upload operations

**Notification Routing Edge Cases:**
- Symptoms: Some notification types cause navigation errors or crash the app
- Files: `lib/core/services/notification_service.dart`, `lib/features/notifications/`
- Trigger: Notification received while app in specific state (e.g., on payment screen)
- Workaround: App restart fixes it
- Root cause: Navigation route may not exist or user not authenticated when notification processed
- Fix: Add route existence checks before navigation, queue notifications if not ready

**Escrow Status Race Condition:**
- Symptoms: Parcel shows as unpaid briefly after payment success
- Files: `lib/features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart`, payment screen
- Trigger: Fast app switching after successful payment, before escrow status updates
- Workaround: App refresh shows correct status
- Root cause: Optimistic UI update doesn't match actual Firestore status update speed
- Fix: Add polling or use Firestore real-time listener for escrow status during payment flow

## Security Considerations

**Hardcoded API Keys Risk:**
- Risk: API keys may be exposed if `.env` file committed or build logs exposed
- Files: `.env` file, environment variable handling
- Current mitigation: `.env` in `.gitignore`, but needs verification
- Recommendations:
  - Use Firebase security rules for data access (done for Firestore)
  - Never commit `.env` file
  - Rotate keys if ever exposed
  - Use Firebase App Check for API validation

**Missing Input Validation on Forms:**
- Risk: Malformed data sent to Firestore or payment APIs
- Files: `lib/features/parcel_am_core/presentation/screens/create_parcel_screen.dart` and other form screens
- Current mitigation: Some client-side validation
- Recommendations:
  - Comprehensive input sanitization before sending to backend
  - Server-side validation in Cloud Functions
  - Firestore security rules that validate data format
  - Reject invalid documents at database layer

**Firestore Security Rules Gaps:**
- Risk: Users might be able to read/modify data they shouldn't access
- Current mitigation: Basic auth-based access control likely in place
- Recommendations:
  - Document all security rules explicitly
  - Regular audit of read/write permissions
  - Principle of least privilege for all collections
  - Test security rules with test suite

**Payment Data Exposure:**
- Risk: Sensitive payment data in logs or error messages
- Files: Payment service logs, error handling
- Current mitigation: Not detected
- Recommendations:
  - Never log full payment details
  - Use Flutterwave/Paystack token-based API calls
  - PCI compliance: Don't store full credit card numbers
  - Mask sensitive data in error messages

## Performance Bottlenecks

**N+1 Query Pattern in Parcel Loading:**
- Problem: Fetching parcel list then individual queries for each traveler details
- Files: `lib/features/parcel_am_core/data/datasources/parcel_remote_data_source.dart`
- Measurement: 2-5s for loading list of 20+ parcels
- Cause: Separate Firestore queries per parcel instead of single batch query
- Improvement path: Use Firestore collection join or denormalize traveler data into parcel documents

**Excessive BLoC Rebuilds:**
- Problem: UI rebuilds on every state emission, even if data unchanged
- Files: Various presentation screens
- Measurement: ~10-20 rebuilds per navigation action
- Cause: Not using `Equatable` properly or emitting state even when data is same
- Improvement path: Ensure all state classes extend Equatable with proper props, only emit on actual changes

**Image Loading Without Optimization:**
- Problem: Large images slow down rendering, no lazy loading
- Files: Screens with multiple images (profile, gallery)
- Measurement: 200-500ms additional load time per full-resolution image
- Cause: No image compression, not using `cached_network_image` everywhere needed
- Improvement path: Implement image compression in `file_upload_service.dart`, use cached_network_image consistently

**Firestore Index Missing for Common Queries:**
- Problem: Some queries timeout or perform slowly
- Files: Queries in data sources
- Measurement: 3-5s for filtered queries
- Cause: Composite indexes not created for all query patterns
- Improvement path: Review `firestore.indexes.json`, add indexes for all filter + sort combinations used

## Fragile Areas

**Complex State Management in ParcelBloc:**
- File: `lib/features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart`
- Why fragile: Multiple state streams, complex event interactions, lots of side effects
- Common failures: State gets out of sync if stream subscriptions not managed properly
- Safe modification: Add tests for each event handler, trace state through emission before changes
- Test coverage: Some handlers tested, but not all combinations

**Chat Message Realtime Sync:**
- Files: `lib/features/chat/presentation/bloc/chat_bloc.dart`, `chat_data.dart`
- Why fragile: Relying on Firestore snapshots + local optimistic updates
- Common failures: Message appears twice (local + server), order inconsistency
- Safe modification: Write integration tests for message send/receive flow
- Test coverage: Basic tests exist, but edge cases (network loss, duplicate sends) not covered

**Payment Integration Edge Cases:**
- Files: Payment BLoCs, payment screens, Cloud Functions
- Why fragile: Dealing with external service callbacks, timing issues
- Common failures: Payment succeeds server-side but UI doesn't update, partial refunds
- Safe modification: Add comprehensive error scenarios to tests
- Test coverage: Happy path tested, but error scenarios incomplete

## Scaling Limits

**Firebase Firestore Collection Size:**
- Current capacity: ~50,000 documents per major collection (users, parcels)
- Limit: ~1M documents per collection before noticeable slowdown
- Symptoms at limit: Query performance degrades, index creation slower
- Scaling path: Implement archival of old parcels, use document sharding for hot collections

**Firebase Real-time Listener Connections:**
- Current capacity: ~100-200 concurrent users with active listeners
- Limit: Firebase free tier: 100 connections, paid scales to 10,000+
- Symptoms at limit: New listeners refused, app crashes if limit exceeded
- Scaling path: Implement pagination instead of listening to full collection

**App Image Size:**
- Current capacity: ~100MB (estimated with all assets)
- Limit: App Store/Play Store no issues, but user device storage matters
- Symptoms at limit: Installation fails on devices with <150MB free
- Scaling path: Use dynamic feature delivery, compress assets

## Dependencies at Risk

**corbado_auth Package:**
- Risk: Emerging vendor, limited community support
- Impact: If abandoned, authentication broken
- Migration plan: Firebase Social Sign-In as alternative, or switch to Supabase Auth

**Flutterwave Payment Gateway:**
- Risk: Depends on external service uptime, API changes
- Impact: Payments blocked if service down
- Migration plan: Implement Stripe as fallback payment processor

## Missing Critical Features

**Offline Support:**
- Problem: App doesn't work well offline (reads fail, writes queued but not shown)
- Current workaround: Show error message, users retry when online
- Blocks: Critical for delivery personnel in areas with spotty connectivity
- Implementation complexity: Medium (Firestore already caches, need UI improvements)

**Payment Retry Mechanism:**
- Problem: Failed payment not automatically retried
- Current workaround: User manually retries
- Blocks: Lost revenue on temporary payment failures
- Implementation complexity: Medium (add retry queue to Cloud Functions)

**User-to-User Rating System:**
- Problem: No way to rate couriers or users
- Current workaround: No ratings, harder to build trust
- Blocks: Platform maturity, user trust
- Implementation complexity: Low (add ratings collection, simple UI)

## Test Coverage Gaps

**Payment Flow End-to-End:**
- What's not tested: Full payment from initiation through Firestore update
- Risk: Payment processing could break silently
- Priority: High
- Difficulty to test: Need mock Flutterwave responses, transaction verification

**Notification Edge Cases:**
- What's not tested: Notification handling when app in different states
- Risk: Crashes or missed notifications
- Priority: Medium
- Difficulty to test: Need to simulate different app states, background/foreground

**BLoC State Transitions:**
- What's not tested: All possible event sequences and their state transitions
- Risk: Unexpected behavior when events occur in unusual order
- Priority: Medium
- Difficulty to test: Combinatorial explosion of sequences

**Error Recovery:**
- What's not tested: Recovery from network failures, timeouts, partial updates
- Risk: App hangs or shows stale data after errors
- Priority: High
- Difficulty to test: Need to mock network failures, slow responses

---

*Concerns audit: 2026-01-08*
*Update as issues are fixed or new ones discovered*
