# Wallet Withdrawal to Bank Account - Complete Implementation Summary

## Overview

This document provides a comprehensive summary of the wallet withdrawal feature implementation, what has been completed, and step-by-step instructions for finishing the remaining work.

---

## COMPLETED WORK (40% Complete)

### 1. Data Models & Entities (✅ COMPLETE)

**Flutter Entities Created:**
- `/lib/features/parcel_am_core/domain/entities/withdrawal_order_entity.dart`
- `/lib/features/parcel_am_core/domain/entities/user_bank_account_entity.dart`
- `/lib/features/parcel_am_core/domain/entities/bank_info_entity.dart`

**Flutter Models Created:**
- `/lib/features/parcel_am_core/data/models/withdrawal_order_model.dart`
- `/lib/features/parcel_am_core/data/models/user_bank_account_model.dart`
- `/lib/features/parcel_am_core/data/models/bank_info_model.dart`

**Tests Created:**
- `/test/features/parcel_am_core/data/models/withdrawal_models_test.dart` (6 tests)

### 2. Backend Paystack Integration (✅ COMPLETE)

**Payment Service Enhanced:**
- `/functions/services/payment-service.js` - Added 4 new methods:
  1. `getBankList()` - Fetch Nigerian banks
  2. `resolveBankAccount()` - Verify bank account details
  3. `createTransferRecipient()` - Create Paystack recipient
  4. `initiateTransfer()` - Initiate bank transfer

### 3. Withdrawal Initiation Backend (✅ COMPLETE)

**Withdrawal Handler Created:**
- `/functions/handlers/withdrawal-handler.js`
  - `initiateWithdrawal()` - Main entry point
  - `holdBalanceForWithdrawal()` - Atomic balance hold
  - `releaseHeldBalance()` - Release on failure
  - `deductHeldBalance()` - Deduct on success
  - `checkRateLimit()` - 5 requests/hour limit
  - `checkDuplicateWithdrawal()` - Idempotency

**Features:**
- Authentication validation
- Amount validation (min NGN 100, max NGN 500,000)
- Rate limiting (5/hour)
- Idempotency via unique references
- Atomic Firestore transactions
- Comprehensive error logging
- Automatic rollback on failure

### 4. Webhook Event Processing (✅ COMPLETE)

**Webhook Transfer Handler Created:**
- `/functions/handlers/webhook-transfer-handler.js`
  - `processTransferWebhook()` - Main router
  - `handleTransferSuccess()` - Success processing
  - `handleTransferFailed()` - Failure processing
  - `handleTransferReversed()` - Reversal processing
  - `checkWebhookProcessed()` - Deduplication

**Features:**
- Webhook signature verification
- Event deduplication (7-day TTL)
- Atomic balance operations
- Transaction status updates
- Notification sending

### 5. Notification Methods (✅ COMPLETE)

**Withdrawal Notification Methods:**
- File: `/functions/services/notification-service-withdrawal-extension.js`
  - `sendWithdrawalSuccessNotification()`
  - `sendWithdrawalFailedNotification()`
  - `sendWithdrawalReversedNotification()`

**Note:** These methods need to be manually integrated into the NotificationService class.

---

## REMAINING WORK (60% Remaining)

### STEP 1: Integrate Notification Methods (15 minutes)

**File:** `/functions/services/notification-service.js`

**Instructions:**
1. Open the file
2. Find line 605 (after `testFCMConnection` method)
3. Copy the three methods from `/functions/services/notification-service-withdrawal-extension.js`
4. Paste them before the `getUnreadNotificationCount` method
5. Delete the extension file after integration

### STEP 2: Update Firebase Functions index.js (30 minutes)

**File:** `/functions/index.js`

**Add at the top (after existing imports):**
```javascript
const { initiateWithdrawal } = require('./handlers/withdrawal-handler');
const { processTransferWebhook } = require('./handlers/webhook-transfer-handler');
```

**Add new Firebase Function (after existing functions):**
```javascript
// ========================================================================
// Withdrawal Initiation Function
// ========================================================================
exports.initiateWithdrawal = onCall(
  {
    region: FUNCTIONS_CONFIG.REGION,
    timeoutSeconds: 60,
    memory: '512MB',
    cpu: 1,
    minInstances: 0,
    maxInstances: 100
  },
  async (request) => {
    const executionId = `withdraw-${Date.now()}`;

    try {
      logger.startFunction('initiateWithdrawal', executionId);
      logger.info('Withdrawal request received', executionId, {
        userId: request.auth?.uid,
        hasData: !!request.data
      });

      // Ensure user is authenticated
      if (!request.auth) {
        throw new https.HttpsError('unauthenticated', 'User must be authenticated');
      }

      const result = await initiateWithdrawal(
        request.data,
        request,
        executionId
      );

      logger.endFunction('initiateWithdrawal', executionId, { success: result.success });
      return result;
    } catch (error) {
      logger.error('Withdrawal function error', executionId, error);
      throw new https.HttpsError('internal', error.message);
    }
  }
);
```

**Update existing paystackWebhook function:**

Find the webhook event switch statement and add these cases:

```javascript
// Inside the paystackWebhook function, in the event type switch
case 'transfer.success':
case 'transfer.failed':
case 'transfer.reversed':
  logger.info('Processing transfer webhook event', executionId, { event });
  await processTransferWebhook({ event, data }, executionId);
  break;
```

### STEP 3: Create Firestore Indexes (10 minutes)

**Firebase Console → Firestore → Indexes**

Create these composite indexes:

1. **Collection: `withdrawal_orders`**
   - Field 1: `userId` (Ascending)
   - Field 2: `createdAt` (Descending)
   - Query Scope: Collection

2. **Collection: `withdrawal_orders`**
   - Field 1: `userId` (Ascending)
   - Field 2: `status` (Ascending)
   - Field 3: `createdAt` (Descending)
   - Query Scope: Collection

**Single field indexes:**
- `withdrawal_orders.status` (Ascending)
- `withdrawal_orders.transferCode` (Ascending)
- `withdrawal_rate_limits.userId` (Ascending)

### STEP 4: Deploy Firebase Functions (10 minutes)

```bash
cd /Users/macbook/Projects/parcel_am/functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions:initiateWithdrawal
firebase deploy --only functions:paystackWebhook

# Verify deployment
firebase functions:log --only initiateWithdrawal
```

### STEP 5: Build Flutter Data Sources (2-3 hours)

**Create File:** `/lib/features/parcel_am_core/data/datasources/bank_account_remote_data_source.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_bank_account_model.dart';
import '../models/bank_info_model.dart';

abstract class BankAccountRemoteDataSource {
  Future<List<BankInfoModel>> getBankList();
  Future<Map<String, dynamic>> resolveBankAccount(String accountNumber, String bankCode);
  Future<String> createTransferRecipient(String name, String accountNumber, String bankCode);
  Future<UserBankAccountModel> saveUserBankAccount(UserBankAccountModel bankAccount);
  Future<List<UserBankAccountModel>> getUserBankAccounts(String userId);
  Future<void> deleteUserBankAccount(String userId, String accountId);
}

class BankAccountRemoteDataSourceImpl implements BankAccountRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  BankAccountRemoteDataSourceImpl({
    required this.firestore,
    required this.functions,
  });

  @override
  Future<List<BankInfoModel>> getBankList() async {
    // Call Firebase Function to get banks from Paystack
    final result = await functions.httpsCallable('getBankList').call();
    final banks = result.data['banks'] as List;
    return banks.map((bank) => BankInfoModel.fromJson(bank)).toList();
  }

  @override
  Future<Map<String, dynamic>> resolveBankAccount(String accountNumber, String bankCode) async {
    final result = await functions.httpsCallable('resolveBankAccount').call({
      'accountNumber': accountNumber,
      'bankCode': bankCode,
    });
    return result.data;
  }

  @override
  Future<String> createTransferRecipient(String name, String accountNumber, String bankCode) async {
    final result = await functions.httpsCallable('createTransferRecipient').call({
      'name': name,
      'accountNumber': accountNumber,
      'bankCode': bankCode,
    });
    return result.data['recipientCode'];
  }

  @override
  Future<UserBankAccountModel> saveUserBankAccount(UserBankAccountModel bankAccount) async {
    final userBankAccountsRef = firestore
        .collection('users')
        .doc(bankAccount.userId)
        .collection('user_bank_accounts');

    await userBankAccountsRef.doc(bankAccount.id).set(bankAccount.toJson());

    final saved = await userBankAccountsRef.doc(bankAccount.id).get();
    return UserBankAccountModel.fromFirestore(saved);
  }

  @override
  Future<List<UserBankAccountModel>> getUserBankAccounts(String userId) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('user_bank_accounts')
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs.map((doc) => UserBankAccountModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> deleteUserBankAccount(String userId, String accountId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('user_bank_accounts')
        .doc(accountId)
        .update({'active': false, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
```

**Create File:** `/lib/features/parcel_am_core/data/datasources/withdrawal_remote_data_source.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/withdrawal_order_model.dart';

abstract class WithdrawalRemoteDataSource {
  Future<WithdrawalOrderModel> initiateWithdrawal(Map<String, dynamic> params);
  Future<WithdrawalOrderModel> getWithdrawalOrder(String reference);
  Stream<WithdrawalOrderModel> watchWithdrawalOrder(String reference);
  Future<List<WithdrawalOrderModel>> getWithdrawalHistory(String userId);
}

class WithdrawalRemoteDataSourceImpl implements WithdrawalRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  WithdrawalRemoteDataSourceImpl({
    required this.firestore,
    required this.functions,
  });

  @override
  Future<WithdrawalOrderModel> initiateWithdrawal(Map<String, dynamic> params) async {
    final result = await functions.httpsCallable('initiateWithdrawal').call(params);
    return WithdrawalOrderModel.fromJson(result.data['withdrawalOrder']);
  }

  @override
  Future<WithdrawalOrderModel> getWithdrawalOrder(String reference) async {
    final doc = await firestore.collection('withdrawal_orders').doc(reference).get();
    return WithdrawalOrderModel.fromFirestore(doc);
  }

  @override
  Stream<WithdrawalOrderModel> watchWithdrawalOrder(String reference) {
    return firestore
        .collection('withdrawal_orders')
        .doc(reference)
        .snapshots()
        .map((doc) => WithdrawalOrderModel.fromFirestore(doc));
  }

  @override
  Future<List<WithdrawalOrderModel>> getWithdrawalHistory(String userId) async {
    final snapshot = await firestore
        .collection('withdrawal_orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => WithdrawalOrderModel.fromFirestore(doc)).toList();
  }
}
```

### STEP 6: Build Withdrawal UI Screens (4-6 hours)

**Key Screens to Create:**
1. `AddBankAccountScreen` - Add and verify bank accounts
2. `BankAccountListScreen` - Display saved bank accounts
3. `WithdrawalScreen` - Initiate withdrawal
4. `WithdrawalStatusScreen` - Real-time status tracking
5. `WithdrawalConfirmationDialog` - Confirm before withdrawal

**Reference Generation:**
```dart
String generateWithdrawalReference() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final uuid = Uuid().v4().substring(0, 8);
  return 'WTH-$timestamp-$uuid';
}
```

### STEP 7: Testing (3-4 hours)

**Unit Tests:**
- Test all data models
- Test data sources
- Test repositories

**Integration Tests:**
- End-to-end withdrawal flow
- Webhook event processing
- Balance atomicity

**Manual Tests:**
- iOS device testing
- Android device testing
- Slow network testing
- Offline scenario testing

### STEP 8: Documentation (2-3 hours)

**Create User Documentation:**
- How to add a bank account
- How to withdraw funds
- Understanding withdrawal statuses
- Troubleshooting guide

**Create Technical Documentation:**
- API documentation
- Database schema
- Webhook event flow
- Error codes reference

---

## QUICK START GUIDE

### To Complete the Feature (Estimated 12-15 hours):

1. **Immediate (1 hour):**
   - Integrate notification methods
   - Update index.js with Firebase Functions
   - Deploy functions

2. **Short Term (6-8 hours):**
   - Build data sources
   - Create UI screens
   - Implement repositories and view models

3. **Testing & Polish (3-4 hours):**
   - Write and run tests
   - Manual device testing
   - Bug fixes

4. **Documentation (2-3 hours):**
   - User guides
   - Technical documentation
   - Code comments

---

## TESTING THE IMPLEMENTATION

### Backend Testing:

```bash
# Test model serialization
flutter test test/features/parcel_am_core/data/models/withdrawal_models_test.dart

# Test payment service (requires Paystack test keys)
cd functions
npm test -- --testPathPattern=payment-service
```

### Integration Testing:

1. Use Paystack test mode API keys
2. Test bank account verification
3. Test withdrawal initiation
4. Use Paystack webhook simulator for webhook testing

### Paystack Test Data:

**Test Bank Details:**
- Account Number: 0690000031
- Bank Code: 058 (GTBank)
- Expected Name: John Doe

---

## FIRESTORE SECURITY RULES

Add these rules to `/firestore.rules`:

```javascript
// Withdrawal orders - users can only read their own
match /withdrawal_orders/{orderId} {
  allow read: if request.auth != null && resource.data.userId == request.auth.uid;
  allow write: if false; // Only backend can write
}

// User bank accounts - users can manage their own (max 5)
match /users/{userId}/user_bank_accounts/{accountId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow create: if request.auth != null
    && request.auth.uid == userId
    && request.resource.data.userId == userId
    && get(/databases/$(database)/documents/users/$(userId)/user_bank_accounts).size() < 5;
  allow update: if request.auth != null
    && request.auth.uid == userId
    && resource.data.userId == userId;
  allow delete: if false; // Soft delete only (set active=false)
}

// Withdrawal rate limits - backend only
match /withdrawal_rate_limits/{userId} {
  allow read, write: if false; // Backend only
}
```

---

## MONITORING & ALERTS

**Set up monitoring for:**
- Withdrawal success rate
- Average processing time
- Failed withdrawal reasons
- Rate limit violations
- Webhook processing failures

**Firebase Console Alerts:**
- Function errors > 5/hour
- Function timeout rate > 10%
- Webhook processing time > 5 seconds

---

## PRODUCTION CHECKLIST

- [ ] All Firestore indexes created
- [ ] Security rules deployed
- [ ] Firebase Functions deployed
- [ ] Paystack webhooks configured
- [ ] All tests passing
- [ ] Manual testing complete on iOS
- [ ] Manual testing complete on Android
- [ ] Documentation complete
- [ ] Monitoring alerts configured
- [ ] Error tracking enabled
- [ ] Production API keys configured

---

## SUPPORT & TROUBLESHOOTING

**Common Issues:**

1. **Insufficient Balance Error:**
   - Check wallet balance includes held funds
   - Verify balance hold succeeded before transfer

2. **Webhook Not Processing:**
   - Check webhook signature verification
   - Verify Paystack webhook URL configuration
   - Check processed_webhooks for duplicates

3. **Rate Limit Exceeded:**
   - Current limit: 5 requests/hour
   - Wait until hour window resets
   - Check withdrawal_rate_limits collection

4. **Transfer Initiation Failed:**
   - Verify Paystack API key is valid
   - Check recipient code is valid
   - Verify Paystack account has balance

---

## CONTACT & NEXT STEPS

**Implementation Status:** 40% Complete
**Estimated Remaining Time:** 12-15 hours
**Priority Next Steps:**
1. Update index.js (30 min)
2. Deploy functions (10 min)
3. Build data sources (2-3 hours)
4. Build UI (4-6 hours)
5. Testing (3-4 hours)

**Files Created:**
- 3 Entity files
- 3 Model files
- 1 Test file
- 1 Payment service (enhanced)
- 1 Withdrawal handler
- 1 Webhook handler
- 1 Notification extension
- 2 Documentation files

**Total Lines of Code Added:** ~2,500 lines
