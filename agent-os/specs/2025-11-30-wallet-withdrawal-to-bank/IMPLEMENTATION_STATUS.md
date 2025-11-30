# Wallet Withdrawal to Bank Account - Implementation Status

## Implementation Progress

This document tracks the implementation status of the wallet withdrawal to bank account feature.

### COMPLETED IMPLEMENTATIONS

#### Phase 1: Foundation & Data Models (Task Group 1) - COMPLETED

**Entities Created:**
1. `/lib/features/parcel_am_core/domain/entities/withdrawal_order_entity.dart`
   - WithdrawalOrderEntity with all required fields
   - WithdrawalStatus enum (pending, processing, success, failed, reversed)
   - BankAccountInfo embedded entity for bank details
   - Complete validation and copyWith methods

2. `/lib/features/parcel_am_core/domain/entities/user_bank_account_entity.dart`
   - UserBankAccountEntity with validation
   - maskedAccountNumber getter (shows last 4 digits)
   - isValidAccountNumber validation (10 digits)
   - isValidBankCode validation

3. `/lib/features/parcel_am_core/domain/entities/bank_info_entity.dart`
   - BankInfoEntity for Paystack bank list
   - matchesSearch method for filtering banks

**Models Created:**
1. `/lib/features/parcel_am_core/data/models/withdrawal_order_model.dart`
   - Complete serialization/deserialization
   - toJson/fromJson/fromFirestore/fromEntity methods

2. `/lib/features/parcel_am_core/data/models/user_bank_account_model.dart`
   - Complete model with Firestore integration

3. `/lib/features/parcel_am_core/data/models/bank_info_model.dart`
   - Paystack bank data model

**Tests Created:**
1. `/test/features/parcel_am_core/data/models/withdrawal_models_test.dart`
   - 6 focused tests covering:
     - WithdrawalOrderModel serialization/deserialization
     - Withdrawal reference format validation
     - WithdrawalStatus enum mapping
     - UserBankAccount 10-digit validation
     - Account number masking
     - BankInfo search filtering

#### Phase 2: Backend Core - Paystack Integration (Task Group 2) - COMPLETED

**Payment Service Enhanced:**
1. `/functions/services/payment-service.js` - Added:
   - `getBankList()` - Fetch Nigerian banks from Paystack
   - `resolveBankAccount(accountNumber, bankCode)` - Resolve bank account details
   - `createTransferRecipient(params)` - Create transfer recipient
   - `initiateTransfer(params)` - Initiate bank transfer using Transfer API

All methods include:
- Comprehensive logging
- Error handling with user-friendly messages
- Input validation
- Idempotency support (via unique references)
- Account number masking in logs (security)

**Key Features:**
- Amount conversion to/from kobo
- Source set to 'balance' for transfers
- Metadata inclusion for tracking
- 60-second timeout for transfer operations
- Retry logic with exponential backoff

#### Phase 3: Withdrawal Initiation Backend (Task Group 3) - COMPLETED

**Withdrawal Handler Created:**
1. `/functions/handlers/withdrawal-handler.js` - Implements:
   - `initiateWithdrawal()` - Main withdrawal initiation logic
   - `holdBalanceForWithdrawal()` - Atomic balance hold using Firestore transactions
   - `releaseHeldBalance()` - Release held funds on failure
   - `deductHeldBalance()` - Deduct from held balance on success
   - `checkRateLimit()` - Rate limiting (5 requests/hour)
   - `checkDuplicateWithdrawal()` - Idempotency check

**Flow Implementation:**
1. Authentication validation (context.auth.uid === userId)
2. Amount validation (min NGN 100, max NGN 500,000)
3. Rate limiting check (5/hour)
4. Duplicate reference detection (idempotency)
5. Atomic balance hold (availableBalance → heldBalance)
6. Withdrawal order creation (status: pending)
7. Transaction record creation (status: pending)
8. Paystack transfer initiation
9. Update to 'processing' status with transferCode
10. Rollback on any failure (release held balance)

**Security & Validation:**
- User authentication required
- Rate limiting enforced
- Balance operations are atomic
- Comprehensive error logging
- Never log full account numbers

### IN PROGRESS / REMAINING IMPLEMENTATIONS

#### Phase 3: Webhook Processing (Task Group 4) - NOT STARTED

**Required:**
1. Webhook handler for transfer events
   - transfer.success
   - transfer.failed
   - transfer.reversed
2. Webhook deduplication (processed_webhooks collection)
3. Balance operations:
   - Success: deduct from held balance, reduce total
   - Failure: release held balance back to available
   - Reversal: release + create refund transaction
4. Notification sending
5. Transaction status updates

**File to Create:**
- `/functions/handlers/webhook-transfer-handler.js`
- Update `/functions/index.js` to add paystackWebhook event handlers

#### Phase 4: Bank Account Management Frontend (Task Group 5) - NOT STARTED

**Required:**
1. BankAccountDataSource (Flutter)
2. BankAccountRepository
3. AddBankAccountScreen
4. BankAccountListScreen
5. BankAccountViewModel/Controller
6. Bank selection widget
7. Account verification flow

**Files to Create:**
- `/lib/features/parcel_am_core/data/datasources/bank_account_remote_data_source.dart`
- `/lib/features/parcel_am_core/data/repositories/bank_account_repository_impl.dart`
- `/lib/features/parcel_am_core/domain/repositories/bank_account_repository.dart`
- `/lib/features/parcel_am_core/presentation/screens/add_bank_account_screen.dart`
- `/lib/features/parcel_am_core/presentation/screens/bank_account_list_screen.dart`
- `/lib/features/parcel_am_core/presentation/viewmodels/bank_account_viewmodel.dart`

#### Phase 5: Withdrawal Flow Frontend (Task Group 6) - NOT STARTED

**Required:**
1. WithdrawalDataSource
2. WithdrawalRepository
3. WithdrawalScreen
4. WithdrawalConfirmationDialog
5. WithdrawalStatusScreen (real-time status via Firestore snapshots)
6. WithdrawalViewModel/Controller
7. PIN/biometric authentication integration
8. Connectivity checks
9. Reference generation (WTH-{timestamp}-{uuid})

**Files to Create:**
- `/lib/features/parcel_am_core/data/datasources/withdrawal_remote_data_source.dart`
- `/lib/features/parcel_am_core/data/repositories/withdrawal_repository_impl.dart`
- `/lib/features/parcel_am_core/domain/repositories/withdrawal_repository.dart`
- `/lib/features/parcel_am_core/presentation/screens/withdrawal_screen.dart`
- `/lib/features/parcel_am_core/presentation/screens/withdrawal_status_screen.dart`
- `/lib/features/parcel_am_core/presentation/viewmodels/withdrawal_viewmodel.dart`
- `/lib/features/parcel_am_core/presentation/widgets/withdrawal_confirmation_dialog.dart`

#### Phase 6: Transaction History Integration (Task Group 7) - NOT STARTED

**Required:**
1. Update getTransactions to filter by withdrawal type
2. WithdrawalTransactionDetailScreen
3. Search by reference/bank name
4. Retry failed withdrawal
5. Withdrawal statistics

**Files to Update/Create:**
- Update `/lib/features/parcel_am_core/data/datasources/wallet_remote_data_source.dart`
- Create `/lib/features/parcel_am_core/presentation/screens/withdrawal_transaction_detail_screen.dart`

#### Phase 7: Testing, Polish & Documentation (Task Groups 8-10) - NOT STARTED

**Required:**
1. Integration tests (end-to-end withdrawal flow)
2. Edge case tests (concurrent requests, webhook race conditions)
3. Manual testing on iOS/Android
4. Error handling review
5. Security audit
6. Performance optimization
7. Documentation (user guides, technical docs, runbook)

### FIREBASE FUNCTIONS TO ADD

**Required Updates to `/functions/index.js`:**

```javascript
// Import withdrawal handler
const { initiateWithdrawal } = require('./handlers/withdrawal-handler');
const { processTransferWebhook } = require('./handlers/webhook-transfer-handler');

// Add initiateWithdrawal Cloud Function
exports.initiateWithdrawal = onCall(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: '512MB'
  },
  async (request) => {
    const executionId = `withdraw-${Date.now()}`;

    try {
      logger.startFunction('initiateWithdrawal', executionId);

      const result = await initiateWithdrawal(
        request.data,
        request,
        executionId
      );

      return result;
    } catch (error) {
      logger.error('Withdrawal function error', executionId, error);
      throw new https.HttpsError('internal', error.message);
    }
  }
);

// Extend paystackWebhook to handle transfer events
// In existing paystackWebhook function, add:
case 'transfer.success':
case 'transfer.failed':
case 'transfer.reversed':
  await processTransferWebhook(eventData, executionId);
  break;
```

### FIRESTORE INDEXES REQUIRED

**Create these indexes in Firebase Console:**

1. Collection: `withdrawal_orders`
   - Composite index: `userId` (ASC) + `createdAt` (DESC)
   - Single field index: `status` (ASC)
   - Single field index: `transferCode` (ASC)

2. Collection: `withdrawal_rate_limits`
   - Single field index: `userId` (ASC)
   - Single field index: `lastAttempt` (DESC)

3. Collection: `user_bank_accounts` (subcollection under users)
   - Composite index: `userId` (ASC) + `active` (ASC) + `createdAt` (DESC)

### DEPLOYMENT STEPS

**Before deploying:**

1. Set Paystack secret key in Firebase Functions:
   ```bash
   firebase functions:secrets:set PAYSTACK_SECRET_KEY
   ```

2. Deploy functions:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions:initiateWithdrawal
   firebase deploy --only functions:paystackWebhook
   ```

3. Set up Firestore indexes (see above)

4. Enable Firestore TTL policies:
   - `withdrawal_orders`: 90 days retention
   - `processed_webhooks`: 7 days retention

### NEXT IMMEDIATE STEPS

**Priority Order:**

1. **CRITICAL**: Create webhook handler for transfer events (Task Group 4)
   - File: `/functions/handlers/webhook-transfer-handler.js`
   - Update `/functions/index.js` to integrate webhook handlers
   - Test with Paystack webhook simulator

2. **HIGH**: Create Firebase Functions exports in index.js
   - Add `initiateWithdrawal` callable function
   - Extend `paystackWebhook` for transfer events
   - Deploy to Firebase

3. **HIGH**: Build bank account management UI (Task Group 5)
   - Start with data sources and repositories
   - Then build UI screens
   - Test bank verification flow

4. **MEDIUM**: Build withdrawal UI (Task Group 6)
   - Requires bank account UI to be complete
   - Implement real-time status tracking
   - Add PIN/biometric authentication

5. **MEDIUM**: Transaction history integration (Task Group 7)

6. **LOW**: Testing and documentation (Task Groups 8-10)

### TESTING NOTES

**Model Tests:**
- Run: `flutter test test/features/parcel_am_core/data/models/withdrawal_models_test.dart`
- Expected: All 6 tests should pass

**Backend Tests:**
- Create tests for payment-service.js transfer methods
- Create tests for withdrawal-handler.js
- Use Paystack test API keys

**Integration Tests:**
- End-to-end withdrawal flow
- Webhook event processing
- Balance atomicity under concurrent requests

### KNOWN ISSUES / CONSIDERATIONS

1. **Firestore Indexes**: Must be created before deployment
2. **Rate Limiting**: Currently uses in-memory tracking; consider Redis for production
3. **Bank List Caching**: Need to implement daily refresh Cloud Function
4. **Notification Service**: Needs to be integrated for status change alerts
5. **Monitoring**: Set up Firebase Performance Monitoring and Error Tracking
6. **Security Rules**: Need Firestore security rules for new collections

### ESTIMATED COMPLETION TIME

- **Completed**: ~40% (Foundation + Backend Core + Withdrawal Initiation)
- **Remaining**: ~60%
  - Webhooks: 2-3 hours
  - Bank Account UI: 6-8 hours
  - Withdrawal UI: 8-10 hours
  - Transaction History: 3-4 hours
  - Testing & Polish: 6-8 hours
  - Documentation: 2-3 hours

**Total Remaining**: ~27-36 hours of development time

