# External Integrations

**Analysis Date:** 2026-01-08

## APIs & External Services

**Payment Processing:**
- Flutterwave - Primary payment gateway for transactions
  - SDK/Client: Custom integration in `functions/services/flutterwave-service.js`
  - Auth: API key via environment variables
  - Endpoints: Charge payment, verify transaction, get banks
  - Usage: One-time payments and wallet funding

- Paystack - Secondary payment processor
  - SDK/Client: Custom service in `lib/core/services/paystack_service.dart`
  - Auth: Public/private keys in configuration
  - Usage: Payment collection and verification

**Authentication:**
- Corbado - Passkey authentication provider
  - SDK/Client: `corbado_auth` package
  - Auth: Project ID configuration
  - Location: `lib/features/passkey/data/datasources/passkey_remote_data_source.dart`
  - Features: Sign up, sign in, append/remove passkeys

## Data Storage

**Databases:**
- Firebase Firestore - Primary database
  - Connection: Via Firebase SDK
  - Collections: users, parcels, chats, notifications, escrows, transactions, wallets, banks, funding_orders, withdrawal_orders
  - Indexes: Multiple composite indexes defined in `firestore.indexes.json`
  - Example indexes:
    - `parcels`: travelerId + lastStatusUpdate
    - `chats`: participantIds + lastMessageTime
    - `notifications`: userId + timestamp
    - `funding_orders`: userId + status + time_created

**File Storage:**
- Firebase Storage - User uploads and media
  - SDK/Client: `firebase_storage` package
  - Auth: Service account credentials
  - Usage: Profile images, ID documents, proof of delivery
  - Location: `lib/core/services/firebase_storage_service.dart`

- Custom File Upload Service:
  - Location: `lib/core/services/file_upload_service.dart`
  - Handles: Image picking, compression, upload orchestration

**Caching:**
- Cached Network Image - Image caching
  - Package: `cached_network_image` v3.4.1
  - Usage: Display cached images from Firebase Storage

- Firebase local caching - Automatic offline support
  - Firestore: Built-in persistence layer

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication - Session management
  - Implementation: Firebase Auth SDK with email/password and OAuth
  - Token storage: Handled by Firebase SDK
  - Session: JWT refresh tokens via Firebase

- Corbado Passkey Authentication - Secure passwordless auth
  - Implementation: `corbado_auth` SDK
  - Location: `lib/features/passkey/presentation/screens/passkey_management_screen.dart`
  - Features: Manage multiple passkeys per user

**Route Protection:**
- AuthGuard - Middleware for protected routes
  - Location: `lib/core/services/auth/auth_guard.dart`
  - Validates: User authentication, KYC status
  - Blocks: Unverified users from payment/sensitive operations

## Notifications

**Push Notifications:**
- Firebase Cloud Messaging - Remote push notifications
  - Package: `firebase_messaging` v16.0.4
  - Handler: `lib/core/services/notification_service.dart`
  - Topics: Broadcast to user segments

**Local Notifications:**
- flutter_local_notifications - Local device notifications
  - Package: `flutter_local_notifications` v18.0.1
  - Usage: Offline alerts, reminders
  - Channels: High-priority, low-priority

**App Badges:**
- app_badge_plus - Badge notification count
  - Package: `app_badge_plus` v1.2.2
  - Usage: Show unread message/notification count on app icon

**Notification Handlers:**
- Location: `lib/core/services/notification_service.dart`
- Features: Chat notifications, payment status, delivery updates
- Navigation: Routes users to relevant screens based on notification type

## Location Services

**Geolocation:**
- geolocator package - GPS location access
  - Usage: Track delivery location, find nearby users
  - Permissions: Requested at runtime with `permission_service`

## Media Selection

**Image/File Selection:**
- image_picker - Camera and gallery access
  - Usage: Profile pictures, ID documents
  - Platforms: iOS and Android native implementation

- file_picker - Generic file selection
  - Usage: Document uploads for KYC

## Monitoring & Observability

**Error Tracking:**
- Firebase Crashlytics - Exception tracking
  - Integration: Via Firebase SDK
  - Captures: Crashes, errors, warnings
  - Location: Integrated in error handlers

**Logging:**
- Custom logger - Application logging
  - Location: `lib/core/utils/logger.dart`
  - Firebase: Cloud Functions logging

## Backend Services

**Firebase Cloud Functions:**
- Location: `functions/` directory (Node.js/JavaScript)
- Entry: `index.js`
- Services:
  - `flutterwave-service.js` - Payment processing and webhooks
  - User account management
  - Transaction processing
  - Notification triggers

## Environment Configuration

**Development:**
- Required env vars: FIREBASE_PROJECT_ID, CORBADO_PROJECT_ID, FLUTTERWAVE_KEY, PAYSTACK_KEY
- Secrets location: `.env` file (gitignored)
- Mock/stub services: Firebase Emulator Suite (if used locally)
- Database: Cloud Firestore development project

**Staging:**
- Uses staging Firebase project
- Payment: Test/sandbox mode for Flutterwave and Paystack
- Separate staging database collections
- Notifications: Real but tagged as staging

**Production:**
- Secrets management: Firebase project environment variables
- Database: Production Firestore with daily backups
- Payments: Live Flutterwave/Paystack accounts
- Notifications: Real FCM production keys
- Location: Google Play Store and Apple App Store builds

## Webhooks & Callbacks

**Incoming:**
- Flutterwave Webhooks - Payment verification
  - Endpoint: `functions/flutterwave-service.js`
  - Verification: HMAC signature validation
  - Events: Payment successful, transaction failed
  - Handler: Updates wallet balance, transaction status

- Paystack Webhooks - Payment events
  - Similar structure to Flutterwave
  - Verifies payment completion

**Outgoing:**
- Chat notifications - User-to-user messages
  - Triggered when message sent
  - Sends FCM notification to recipient

- Payment status updates - Transaction callbacks
  - Notifies user of payment completion/failure
  - Triggers wallet balance updates

## API Integration Points

**REST Endpoints (via Cloud Functions):**
- `/api/payments/initialize` - Start payment
- `/api/payments/verify` - Verify payment
- `/api/transactions/history` - Get transaction history
- Custom endpoints for wallet, parcel operations

**GraphQL:**
- Not detected in current implementation
- REST via Firebase Cloud Functions only

---

*Integration audit: 2026-01-08*
*Update when adding/removing external services*
