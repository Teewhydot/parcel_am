# Wallet Withdrawal Technical Guide

## Overview
This document provides technical details for developers working with the wallet withdrawal feature. It covers architecture, data flows, error handling, and integration points.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Data Models](#data-models)
3. [Withdrawal Flow](#withdrawal-flow)
4. [Webhook Processing](#webhook-processing)
5. [Error Handling](#error-handling)
6. [Security Implementation](#security-implementation)
7. [Performance Optimization](#performance-optimization)
8. [Testing Strategy](#testing-strategy)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────┐
│   Flutter App   │
│  (Presentation) │
└────────┬────────┘
         │
         ├─→ BLoC/State Management
         │   └─→ WithdrawalBloc
         │   └─→ BankAccountBloc
         │
         ├─→ Repositories
         │   └─→ WithdrawalRepository
         │   └─→ BankAccountRepository
         │
         ├─→ Data Sources
         │   └─→ WithdrawalRemoteDataSource
         │   └─→ BankAccountRemoteDataSource
         │
         ├─→ Firebase Functions
         │   └─→ initiateWithdrawal
         │   └─→ paystackWebhook (transfer events)
         │
         ├─→ Paystack API
         │   └─→ Transfer API
         │   └─→ Transfer Recipient API
         │   └─→ Bank Resolution API
         │
         └─→ Firestore Database
             └─→ withdrawal_orders
             └─→ user_bank_accounts
             └─→ transactions
             └─→ wallets
```

### Layer Responsibilities

**Presentation Layer**
- `WithdrawalScreen`: User initiates withdrawal
- `WithdrawalStatusScreen`: Real-time status tracking
- `WithdrawalTransactionDetailScreen`: Detailed view with retry option
- `AddBankAccountScreen`: Bank account verification
- `BankAccountListScreen`: Manage saved accounts

**Domain Layer**
- `WithdrawalRepository`: Business logic abstraction
- `BankAccountRepository`: Bank account operations
- `WithdrawalOrderEntity`: Domain model for withdrawals
- `UserBankAccountEntity`: Domain model for bank accounts

**Data Layer**
- `WithdrawalRemoteDataSource`: Firebase Functions integration
- `BankAccountRemoteDataSource`: Paystack integration
- `WithdrawalOrderModel`: Data transfer object
- `UserBankAccountModel`: Data transfer object

**Backend Layer**
- `initiateWithdrawal`: Cloud Function for withdrawal initiation
- `paystackWebhook`: Webhook handler for transfer status updates
- `payment-service.js`: Paystack API integration

---

## Data Models

### WithdrawalOrderEntity

```dart
class WithdrawalOrderEntity {
  final String id;                    // Format: WTH-{timestamp}-{uuid}
  final String userId;                // User who initiated withdrawal
  final double amount;                // Amount in NGN
  final BankAccountInfo bankAccount;  // Embedded bank details
  final WithdrawalStatus status;      // Current status
  final String recipientCode;         // Paystack recipient code
  final String? transferCode;         // Paystack transfer code
  final DateTime createdAt;           // When withdrawal was initiated
  final DateTime updatedAt;           // Last status update
  final DateTime? processedAt;        // When completed/failed/reversed
  final Map<String, dynamic> metadata;// Additional data
  final String? failureReason;        // Reason if failed
  final String? reversalReason;       // Reason if reversed
}
```

### WithdrawalStatus Enum

```dart
enum WithdrawalStatus {
  pending,     // Initial state, awaiting processing
  processing,  // Paystack transfer initiated
  success,     // Transfer completed successfully
  failed,      // Transfer failed
  reversed,    // Transfer was reversed by bank
}
```

### UserBankAccountEntity

```dart
class UserBankAccountEntity {
  final String id;              // Document ID
  final String userId;          // Owner user ID
  final String accountNumber;   // 10-digit account number
  final String accountName;     // Resolved account name
  final String bankCode;        // Bank code (from Paystack)
  final String bankName;        // Bank name
  final String recipientCode;   // Paystack recipient code
  final bool verified;          // Verification status
  final bool active;            // Soft delete flag
  final DateTime createdAt;     // When account was added
  final DateTime updatedAt;     // Last modification
}
```

### BankAccountInfo (Embedded)

```dart
class BankAccountInfo {
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;
}
```

### Firestore Collection Structure

```
users/{userId}/
  ├─ wallet
  └─ user_bank_accounts/
      └─ {accountId}

withdrawal_orders/
  └─ {withdrawalReference}

transactions/
  └─ {transactionId}

system_config/
  └─ banks  // Cached bank list
```

---

## Withdrawal Flow

### End-to-End Flow Diagram

```
1. User Input
   └─→ Enter amount
   └─→ Select bank account
   └─→ Review details

2. Client Validation
   └─→ Check minimum/maximum amount
   └─→ Check available balance
   └─→ Verify internet connection

3. Authentication
   └─→ PIN or biometric

4. Generate Reference
   └─→ Format: WTH-{timestamp}-{uuid}

5. Call initiateWithdrawal Function
   ├─→ Verify authentication
   ├─→ Check for duplicate reference (idempotency)
   ├─→ Hold balance atomically
   ├─→ Create withdrawal order (status: pending)
   ├─→ Create transaction record (type: withdrawal, status: pending)
   ├─→ Call Paystack initiateTransfer API
   ├─→ Update withdrawal order (status: processing)
   └─→ Return withdrawal order details

6. Navigate to Status Screen
   └─→ Listen to Firestore snapshot for real-time updates

7. Webhook Processing
   ├─→ Paystack sends transfer.success event
   │   ├─→ Update withdrawal order (status: success)
   │   ├─→ Deduct held balance
   │   ├─→ Update transaction (status: completed)
   │   └─→ Send success notification
   │
   ├─→ Paystack sends transfer.failed event
   │   ├─→ Update withdrawal order (status: failed)
   │   ├─→ Release held balance
   │   ├─→ Update transaction (status: failed)
   │   └─→ Send failure notification
   │
   └─→ Paystack sends transfer.reversed event
       ├─→ Update withdrawal order (status: reversed)
       ├─→ Release held balance
       ├─→ Create reversal transaction
       ├─→ Update original transaction (status: cancelled)
       └─→ Send reversal notification

8. User Sees Updated Status
   └─→ Real-time via Firestore snapshot
```

### Detailed Initiation Flow

```dart
// 1. Client generates withdrawal reference
final reference = generateWithdrawalReference();
// Output: WTH-1732971234567-a1b2c3d4-e5f6-7890-abcd-ef1234567890

// 2. Validate amount
final isValid = validateWithdrawalAmount(
  amount: 5000.0,
  availableBalance: 10000.0,
);

// 3. Call Firebase Function
final result = await withdrawalRepository.initiateWithdrawal(
  userId: currentUser.id,
  amount: 5000.0,
  recipientCode: selectedAccount.recipientCode,
  withdrawalReference: reference,
  bankAccountId: selectedAccount.id,
);

// 4. Navigate to status screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => WithdrawalStatusScreen(
      withdrawalId: result.id,
    ),
  ),
);

// 5. Listen for real-time updates
withdrawalRepository.watchWithdrawalOrder(withdrawalId).listen((order) {
  // Update UI based on order.status
});
```

### Backend Initiation Logic

```javascript
// Firebase Function: initiateWithdrawal
async function initiateWithdrawal(data, context) {
  const executionId = generateExecutionId();

  // 1. Authenticate user
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated');
  }

  // 2. Extract and validate parameters
  const { userId, amount, recipientCode, withdrawalReference, bankAccountId } = data;
  validateParams({ userId, amount, recipientCode, withdrawalReference, bankAccountId });

  // 3. Check for duplicate (idempotency)
  const existingOrder = await getWithdrawalOrder(withdrawalReference);
  if (existingOrder) {
    return existingOrder; // Return existing order
  }

  // 4. Validate amount
  if (amount < 100 || amount > 500000) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid amount');
  }

  // 5. Rate limiting check
  await checkRateLimit(userId);

  // 6. Hold balance atomically
  await dbHelper.runTransaction(async (transaction) => {
    const walletRef = dbHelper.getDocumentRef(`users/${userId}/wallet/${userId}`);
    const walletDoc = await transaction.get(walletRef);
    const wallet = walletDoc.data();

    if (wallet.availableBalance < amount) {
      throw new Error('Insufficient balance');
    }

    transaction.update(walletRef, {
      availableBalance: wallet.availableBalance - amount,
      heldBalance: wallet.heldBalance + amount,
      updatedAt: dbHelper.getServerTimestamp(),
    });
  });

  // 7. Create withdrawal order
  const withdrawalOrder = await dbHelper.addDocument('withdrawal_orders', {
    id: withdrawalReference,
    userId,
    amount,
    bankAccount: bankAccountDetails,
    status: 'pending',
    recipientCode,
    transferCode: null,
    createdAt: dbHelper.getServerTimestamp(),
    updatedAt: dbHelper.getServerTimestamp(),
    processedAt: null,
    metadata: {},
  });

  // 8. Create transaction record
  await dbHelper.addDocument('transactions', {
    id: generateTransactionId(),
    walletId: userId,
    userId,
    amount,
    type: 'withdrawal',
    status: 'pending',
    currency: 'NGN',
    timestamp: dbHelper.getServerTimestamp(),
    description: `Withdrawal to ${bankAccountDetails.bankName}`,
    referenceId: withdrawalReference,
    metadata: { bankAccount: bankAccountDetails },
    idempotencyKey: withdrawalReference,
  });

  // 9. Call Paystack Transfer API
  const transferResponse = await paymentService.initiateTransfer({
    source: 'balance',
    amount: amount * 100, // Convert to kobo
    recipient: recipientCode,
    reference: withdrawalReference,
    reason: `Wallet withdrawal to ${bankAccountDetails.bankName}`,
    metadata: {
      userId,
      userName: user.name,
      withdrawalOrderId: withdrawalReference,
    },
  });

  // 10. Update withdrawal order with transfer code
  await dbHelper.updateDocument('withdrawal_orders', withdrawalReference, {
    status: 'processing',
    transferCode: transferResponse.data.transfer_code,
    updatedAt: dbHelper.getServerTimestamp(),
  });

  // 11. Return updated order
  return await getWithdrawalOrder(withdrawalReference);
}
```

---

## Webhook Processing

### Webhook Event Flow

```
Paystack → Firebase Function (paystackWebhook)
  └─→ Verify webhook signature
  └─→ Check for duplicate event
  └─→ Extract event data
  └─→ Route to appropriate handler
      ├─→ handleTransferSuccess
      ├─→ handleTransferFailed
      └─→ handleTransferReversed
```

### Transfer Success Handler

```javascript
async function handleTransferSuccess(event, executionId) {
  const { reference, transfer_code, amount, recipient } = event.data;

  try {
    // 1. Find withdrawal order
    const withdrawalOrder = await getWithdrawalOrderByReference(reference);
    if (!withdrawalOrder) {
      logger.warn('Withdrawal order not found', executionId, { reference });
      return;
    }

    // 2. Update withdrawal order
    await dbHelper.runTransaction(async (transaction) => {
      // Update withdrawal order status
      const orderRef = dbHelper.getDocumentRef(`withdrawal_orders/${reference}`);
      transaction.update(orderRef, {
        status: 'success',
        processedAt: dbHelper.getServerTimestamp(),
        updatedAt: dbHelper.getServerTimestamp(),
      });

      // Deduct held balance
      const walletRef = dbHelper.getDocumentRef(`users/${withdrawalOrder.userId}/wallet/${withdrawalOrder.userId}`);
      const walletDoc = await transaction.get(walletRef);
      const wallet = walletDoc.data();

      transaction.update(walletRef, {
        heldBalance: wallet.heldBalance - withdrawalOrder.amount,
        totalBalance: wallet.totalBalance - withdrawalOrder.amount,
        updatedAt: dbHelper.getServerTimestamp(),
      });

      // Update transaction status
      const transactionRef = await getTransactionByReference(reference);
      transaction.update(transactionRef, {
        status: 'completed',
        metadata: {
          ...transactionRef.metadata,
          transferCode: transfer_code,
          completedAt: dbHelper.getServerTimestamp(),
        },
      });
    });

    // 3. Send success notification
    await notificationService.sendWithdrawalSuccessNotification({
      userId: withdrawalOrder.userId,
      amount: withdrawalOrder.amount,
      bankAccountName: withdrawalOrder.bankAccount.accountName,
      bankName: withdrawalOrder.bankAccount.bankName,
      reference,
      expectedArrivalTime: '24 hours',
    }, executionId);

    logger.info('Transfer success processed', executionId, { reference });
  } catch (error) {
    logger.error('Failed to process transfer success', executionId, error);
    throw error;
  }
}
```

### Transfer Failed Handler

```javascript
async function handleTransferFailed(event, executionId) {
  const { reference, transfer_code, status, failureReason } = event.data;

  try {
    const withdrawalOrder = await getWithdrawalOrderByReference(reference);
    if (!withdrawalOrder) {
      logger.warn('Withdrawal order not found', executionId, { reference });
      return;
    }

    await dbHelper.runTransaction(async (transaction) => {
      // Update withdrawal order
      const orderRef = dbHelper.getDocumentRef(`withdrawal_orders/${reference}`);
      transaction.update(orderRef, {
        status: 'failed',
        failureReason,
        processedAt: dbHelper.getServerTimestamp(),
        updatedAt: dbHelper.getServerTimestamp(),
      });

      // Release held balance
      const walletRef = dbHelper.getDocumentRef(`users/${withdrawalOrder.userId}/wallet/${withdrawalOrder.userId}`);
      const walletDoc = await transaction.get(walletRef);
      const wallet = walletDoc.data();

      transaction.update(walletRef, {
        availableBalance: wallet.availableBalance + withdrawalOrder.amount,
        heldBalance: wallet.heldBalance - withdrawalOrder.amount,
        updatedAt: dbHelper.getServerTimestamp(),
      });

      // Update transaction status
      const transactionRef = await getTransactionByReference(reference);
      transaction.update(transactionRef, {
        status: 'failed',
        metadata: {
          ...transactionRef.metadata,
          failureReason,
          failedAt: dbHelper.getServerTimestamp(),
        },
      });
    });

    // Send failure notification
    await notificationService.sendWithdrawalFailedNotification({
      userId: withdrawalOrder.userId,
      amount: withdrawalOrder.amount,
      bankAccountName: withdrawalOrder.bankAccount.accountName,
      reference,
      reason: failureReason,
    }, executionId);

    logger.info('Transfer failure processed', executionId, { reference, failureReason });
  } catch (error) {
    logger.error('Failed to process transfer failure', executionId, error);
    throw error;
  }
}
```

### Transfer Reversed Handler

```javascript
async function handleTransferReversed(event, executionId) {
  const { reference, transfer_code, reversalReason } = event.data;

  try {
    const withdrawalOrder = await getWithdrawalOrderByReference(reference);
    if (!withdrawalOrder) {
      logger.warn('Withdrawal order not found', executionId, { reference });
      return;
    }

    await dbHelper.runTransaction(async (transaction) => {
      // Update withdrawal order
      const orderRef = dbHelper.getDocumentRef(`withdrawal_orders/${reference}`);
      transaction.update(orderRef, {
        status: 'reversed',
        reversalReason,
        processedAt: dbHelper.getServerTimestamp(),
        updatedAt: dbHelper.getServerTimestamp(),
      });

      // Release held balance
      const walletRef = dbHelper.getDocumentRef(`users/${withdrawalOrder.userId}/wallet/${withdrawalOrder.userId}`);
      const walletDoc = await transaction.get(walletRef);
      const wallet = walletDoc.data();

      transaction.update(walletRef, {
        availableBalance: wallet.availableBalance + withdrawalOrder.amount,
        heldBalance: wallet.heldBalance - withdrawalOrder.amount,
        updatedAt: dbHelper.getServerTimestamp(),
      });

      // Create reversal transaction
      await dbHelper.addDocument('transactions', {
        id: generateTransactionId(),
        walletId: withdrawalOrder.userId,
        userId: withdrawalOrder.userId,
        amount: withdrawalOrder.amount,
        type: 'refund',
        status: 'completed',
        currency: 'NGN',
        timestamp: dbHelper.getServerTimestamp(),
        description: `Withdrawal reversal from ${withdrawalOrder.bankAccount.bankName}`,
        referenceId: reference,
        metadata: {
          originalWithdrawal: reference,
          reversalReason,
        },
        idempotencyKey: `${reference}-reversal`,
      });

      // Update original transaction
      const transactionRef = await getTransactionByReference(reference);
      transaction.update(transactionRef, {
        status: 'cancelled',
        metadata: {
          ...transactionRef.metadata,
          reversalReason,
          reversedAt: dbHelper.getServerTimestamp(),
        },
      });
    });

    // Send reversal notification
    await notificationService.sendWithdrawalReversedNotification({
      userId: withdrawalOrder.userId,
      amount: withdrawalOrder.amount,
      bankAccountName: withdrawalOrder.bankAccount.accountName,
      reference,
      reason: reversalReason,
      reversalTransactionId: reversalTxId,
    }, executionId);

    logger.info('Transfer reversal processed', executionId, { reference, reversalReason });
  } catch (error) {
    logger.error('Failed to process transfer reversal', executionId, error);
    throw error;
  }
}
```

---

## Error Handling

### Client-Side Error Mapping

```dart
class WithdrawalErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'insufficient-balance':
          return 'Your available balance is insufficient for this withdrawal. Please check your balance and try again.';

        case 'invalid-amount':
          return 'Withdrawal amount must be between NGN 100 and NGN 500,000.';

        case 'rate-limit-exceeded':
          return 'You have exceeded the maximum withdrawal requests per hour. Please try again later.';

        case 'invalid-recipient':
          return 'The selected bank account is invalid. Please verify your account details.';

        case 'unauthenticated':
          return 'Please sign in to continue.';

        case 'network-error':
          return 'Network error. Please check your connection and try again.';

        case 'timeout':
          return 'Request timed out. Your withdrawal may still be processing. Please check the status.';

        default:
          return 'An unexpected error occurred. Reference: ${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    return 'An error occurred. Please try again.';
  }
}
```

### Backend Error Handling

```javascript
class WithdrawalError extends Error {
  constructor(code, message, details = {}) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

// Usage
if (wallet.availableBalance < amount) {
  throw new WithdrawalError(
    'insufficient-balance',
    'Insufficient available balance',
    { availableBalance: wallet.availableBalance, requestedAmount: amount }
  );
}

// Catch and log
try {
  await processWithdrawal();
} catch (error) {
  if (error instanceof WithdrawalError) {
    logger.error('Withdrawal error', executionId, {
      code: error.code,
      message: error.message,
      details: error.details,
    });
    throw new functions.https.HttpsError(error.code, error.message);
  }

  // Unknown error
  logger.error('Unexpected withdrawal error', executionId, error);
  throw new functions.https.HttpsError('internal', 'An unexpected error occurred');
}
```

### Paystack Error Mapping

```javascript
function mapPaystackError(error) {
  const paystackMessage = error.response?.data?.message || error.message;

  const errorMappings = {
    'Insufficient balance': 'insufficient-paystack-balance',
    'Invalid recipient': 'invalid-recipient',
    'Transfer limit exceeded': 'transfer-limit-exceeded',
    'Account validation failed': 'invalid-account',
  };

  for (const [key, code] of Object.entries(errorMappings)) {
    if (paystackMessage.includes(key)) {
      return new WithdrawalError(code, paystackMessage);
    }
  }

  return new WithdrawalError('paystack-error', paystackMessage);
}
```

---

## Security Implementation

### 1. Authentication & Authorization

```dart
// Client: Require authentication for all withdrawal operations
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw UnauthorizedException();
}

// Backend: Verify authenticated user
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated');
}

// Verify user owns the wallet
if (context.auth.uid !== userId) {
  throw new functions.https.HttpsError('permission-denied');
}
```

### 2. PIN/Biometric Authentication

```dart
// Require before withdrawal confirmation
Future<bool> authenticateUser() async {
  final localAuth = LocalAuthentication();

  try {
    final canAuthenticate = await localAuth.canCheckBiometrics;

    if (canAuthenticate) {
      return await localAuth.authenticate(
        localizedReason: 'Authenticate to confirm withdrawal',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } else {
      // Fall back to PIN
      return await showPinDialog();
    }
  } catch (e) {
    return false;
  }
}
```

### 3. Rate Limiting

```javascript
async function checkRateLimit(userId) {
  const oneHourAgo = Date.now() - (60 * 60 * 1000);

  const recentWithdrawals = await db
    .collection('withdrawal_orders')
    .where('userId', '==', userId)
    .where('createdAt', '>=', oneHourAgo)
    .get();

  if (recentWithdrawals.size >= 5) {
    const oldestWithdrawal = recentWithdrawals.docs[0].data();
    const retryAfter = new Date(oldestWithdrawal.createdAt + (60 * 60 * 1000));

    throw new WithdrawalError(
      'rate-limit-exceeded',
      'Maximum 5 withdrawal requests per hour',
      { retryAfter }
    );
  }
}
```

### 4. Data Encryption

```javascript
// Firestore automatically encrypts data at rest
// Additional sensitive field encryption (if needed)
const crypto = require('crypto');

function encryptField(value, encryptionKey) {
  const cipher = crypto.createCipher('aes-256-cbc', encryptionKey);
  let encrypted = cipher.update(value, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}

// Usage (only if additional encryption needed beyond Firestore)
const encryptedAccountNumber = encryptField(
  accountNumber,
  process.env.ENCRYPTION_KEY
);
```

### 5. Audit Logging

```javascript
async function logWithdrawalAttempt(params) {
  await db.collection('audit_logs').add({
    type: 'withdrawal_attempt',
    userId: params.userId,
    amount: params.amount,
    bankAccountId: params.bankAccountId,
    reference: params.reference,
    ipAddress: params.ipAddress,
    deviceInfo: params.deviceInfo,
    timestamp: dbHelper.getServerTimestamp(),
    status: params.status, // 'success', 'failed', 'blocked'
    reason: params.reason, // If blocked or failed
  });
}
```

### 6. Suspicious Pattern Detection

```javascript
async function detectSuspiciousPatterns(userId) {
  const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000);

  // Check for multiple failed attempts
  const failedWithdrawals = await db
    .collection('withdrawal_orders')
    .where('userId', '==', userId)
    .where('status', '==', 'failed')
    .where('createdAt', '>=', oneDayAgo)
    .get();

  if (failedWithdrawals.size >= 3) {
    // Flag for review
    await flagUserForReview(userId, 'multiple-failed-withdrawals');

    // Notify admins
    await notifyAdmins({
      type: 'suspicious-activity',
      userId,
      reason: `${failedWithdrawals.size} failed withdrawals in 24 hours`,
    });
  }

  // Check for rapid withdrawal requests
  const recentWithdrawals = await db
    .collection('withdrawal_orders')
    .where('userId', '==', userId)
    .where('createdAt', '>=', Date.now() - (5 * 60 * 1000)) // Last 5 minutes
    .get();

  if (recentWithdrawals.size >= 3) {
    throw new WithdrawalError(
      'suspicious-activity',
      'Unusual withdrawal pattern detected. Please contact support.'
    );
  }
}
```

### 7. Secure Logging

```javascript
// Never log sensitive data
function sanitizeLogData(data) {
  return {
    ...data,
    accountNumber: data.accountNumber ? `****${data.accountNumber.slice(-4)}` : undefined,
    recipientCode: '[REDACTED]',
    transferCode: '[REDACTED]',
  };
}

logger.info('Withdrawal initiated', executionId, sanitizeLogData(withdrawalData));
```

---

## Performance Optimization

### 1. Firestore Indexes

Required composite indexes:

```javascript
// withdrawal_orders collection
// Index 1: Query by user and time
{
  collection: 'withdrawal_orders',
  fields: [
    { fieldPath: 'userId', mode: 'ASCENDING' },
    { fieldPath: 'createdAt', mode: 'DESCENDING' },
  ]
}

// Index 2: Query by status (for admin/monitoring)
{
  collection: 'withdrawal_orders',
  fields: [
    { fieldPath: 'status', mode: 'ASCENDING' },
    { fieldPath: 'createdAt', mode: 'DESCENDING' },
  ]
}

// Index 3: Query by user and status
{
  collection: 'withdrawal_orders',
  fields: [
    { fieldPath: 'userId', mode: 'ASCENDING' },
    { fieldPath: 'status', mode: 'ASCENDING' },
    { fieldPath: 'createdAt', mode: 'DESCENDING' },
  ]
}
```

### 2. Pagination

```dart
// Client-side pagination
Future<List<WithdrawalOrderEntity>> getWithdrawalHistory({
  required String userId,
  int limit = 20,
  DocumentSnapshot? startAfter,
}) async {
  Query query = _firestore
      .collection('withdrawal_orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(limit);

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  final snapshot = await query.get();
  return snapshot.docs.map((doc) => WithdrawalOrderModel.fromFirestore(doc)).toList();
}
```

### 3. Bank List Caching

```javascript
// Scheduled function to refresh bank list daily
exports.refreshBankList = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM WAT
  .timeZone('Africa/Lagos')
  .onRun(async (context) => {
    const executionId = 'refresh-bank-list';

    try {
      const banks = await paymentService.getBankList();

      await db.collection('system_config').doc('banks').set({
        banks,
        lastUpdated: dbHelper.getServerTimestamp(),
      });

      logger.info('Bank list refreshed', executionId, { count: banks.length });
    } catch (error) {
      logger.error('Failed to refresh bank list', executionId, error);
    }
  });

// Client-side caching
class BankListCache {
  static List<BankInfo>? _cachedBanks;
  static DateTime? _cacheExpiry;

  static Future<List<BankInfo>> getBanks() async {
    if (_cachedBanks != null && _cacheExpiry != null && DateTime.now().isBefore(_cacheExpiry!)) {
      return _cachedBanks!;
    }

    final doc = await FirebaseFirestore.instance
        .collection('system_config')
        .doc('banks')
        .get();

    _cachedBanks = (doc.data()?['banks'] as List)
        .map((b) => BankInfo.fromJson(b))
        .toList();
    _cacheExpiry = DateTime.now().add(Duration(hours: 24));

    return _cachedBanks!;
  }
}
```

### 4. Function Timeout Configuration

```javascript
// Set appropriate timeout for withdrawal initiation
exports.initiateWithdrawal = functions
  .runWith({
    timeoutSeconds: 60,
    memory: '256MB',
  })
  .https.onCall(async (data, context) => {
    // Function implementation
  });
```

### 5. Connection Pooling (if using external APIs)

```javascript
const axios = require('axios');
const http = require('http');
const https = require('https');

const httpAgent = new http.Agent({ keepAlive: true });
const httpsAgent = new https.Agent({ keepAlive: true });

const paystackClient = axios.create({
  baseURL: 'https://api.paystack.co',
  httpAgent,
  httpsAgent,
  headers: {
    'Authorization': `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
    'Content-Type': 'application/json',
  },
});
```

---

## Testing Strategy

### Unit Tests

```dart
// Test withdrawal amount validation
test('should validate withdrawal amount correctly', () {
  final repository = WithdrawalRepositoryImpl();

  expect(repository.validateWithdrawalAmount(50, 1000), false);   // Too low
  expect(repository.validateWithdrawalAmount(100, 1000), true);   // Min valid
  expect(repository.validateWithdrawalAmount(5000, 1000), false); // Insufficient balance
  expect(repository.validateWithdrawalAmount(500000, 600000), true); // Max valid
  expect(repository.validateWithdrawalAmount(500001, 600000), false); // Too high
});

// Test withdrawal reference generation
test('should generate valid withdrawal reference', () {
  final repository = WithdrawalRepositoryImpl();
  final reference = repository.generateWithdrawalReference();

  expect(reference, startsWith('WTH-'));
  expect(reference.length, greaterThan(40));
});
```

### Widget Tests

```dart
testWidgets('should display withdrawal details correctly', (tester) async {
  final testOrder = WithdrawalOrderEntity(
    id: 'WTH-123',
    userId: 'user1',
    amount: 5000.0,
    bankAccount: BankAccountInfo(
      accountNumber: '1234567890',
      accountName: 'John Doe',
      bankCode: '058',
      bankName: 'GTBank',
    ),
    status: WithdrawalStatus.success,
    recipientCode: 'RCP_123',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: WithdrawalTransactionDetailScreen(
        withdrawalOrder: testOrder,
      ),
    ),
  );

  expect(find.text('₦5,000.00'), findsOneWidget);
  expect(find.text('John Doe'), findsOneWidget);
  expect(find.text('GTBank'), findsOneWidget);
  expect(find.text('Success'), findsOneWidget);
});
```

### Integration Tests

```dart
testWidgets('should complete full withdrawal flow', (tester) async {
  // 1. Setup test environment
  await setupTestFirestore();
  await setupTestUser();
  await setupTestBankAccount();

  // 2. Navigate to withdrawal screen
  await tester.pumpWidget(MyApp());
  await tester.tap(find.text('Withdraw'));
  await tester.pumpAndSettle();

  // 3. Enter amount
  await tester.enterText(find.byType(TextField), '5000');
  await tester.pumpAndSettle();

  // 4. Select bank account
  await tester.tap(find.byType(DropdownButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('GTBank - ****7890'));
  await tester.pumpAndSettle();

  // 5. Confirm withdrawal
  await tester.tap(find.text('Confirm Withdrawal'));
  await tester.pumpAndSettle();

  // 6. Enter PIN
  await enterTestPin(tester);
  await tester.pumpAndSettle();

  // 7. Verify navigation to status screen
  expect(find.byType(WithdrawalStatusScreen), findsOneWidget);
  expect(find.text('Processing'), findsOneWidget);

  // 8. Simulate webhook success
  await simulateWebhookSuccess();
  await tester.pumpAndSettle();

  // 9. Verify success state
  expect(find.text('Success'), findsOneWidget);
});
```

### Backend Tests

```javascript
describe('initiateWithdrawal', () => {
  it('should create withdrawal order and hold balance', async () => {
    const userId = 'testUser123';
    const amount = 5000;

    // Setup
    await setupTestWallet(userId, 10000);
    const recipientCode = await createTestRecipient();

    // Execute
    const result = await initiateWithdrawal({
      userId,
      amount,
      recipientCode,
      withdrawalReference: generateTestReference(),
      bankAccountId: 'testAccount123',
    });

    // Verify
    expect(result.status).toBe('processing');

    const wallet = await getWallet(userId);
    expect(wallet.availableBalance).toBe(5000);
    expect(wallet.heldBalance).toBe(5000);
  });

  it('should reject duplicate withdrawal reference', async () => {
    const reference = generateTestReference();

    // First attempt
    await initiateWithdrawal({ ...testData, withdrawalReference: reference });

    // Second attempt with same reference
    const result = await initiateWithdrawal({ ...testData, withdrawalReference: reference });

    // Should return existing order
    expect(result.id).toBe(reference);
  });
});
```

---

## Monitoring and Observability

### Key Metrics to Track

1. **Withdrawal Success Rate**
   - Formula: `(successful_withdrawals / total_withdrawals) * 100`
   - Target: > 95%

2. **Average Processing Time**
   - Time from initiation to completion
   - Target: < 15 minutes

3. **Failure Rate by Reason**
   - Track common failure reasons
   - Identify patterns

4. **Rate Limit Hit Rate**
   - How often users hit rate limits
   - May indicate UX issues

5. **Webhook Processing Time**
   - Time to process webhook events
   - Target: < 5 seconds

### Logging Best Practices

```javascript
// Structured logging with execution IDs
logger.info('Operation started', executionId, { userId, operation: 'withdrawal' });

// Log with context
logger.error('Operation failed', executionId, {
  userId,
  operation: 'withdrawal',
  error: error.message,
  stack: error.stack,
  context: { amount, reference },
});

// Log performance
const startTime = Date.now();
// ... operation ...
const duration = Date.now() - startTime;
logger.info('Operation completed', executionId, { duration });
```

---

## Deployment Checklist

Before deploying to production:

- [ ] All Firestore indexes created
- [ ] Paystack API keys configured (production keys)
- [ ] Firebase Functions environment variables set
- [ ] Rate limiting thresholds configured
- [ ] Notification service tested
- [ ] Webhook endpoint SSL configured
- [ ] Webhook signature verification enabled
- [ ] Error tracking (Sentry/Firebase Crashlytics) configured
- [ ] Monitoring dashboards set up
- [ ] Backup and disaster recovery plan in place
- [ ] Security audit completed
- [ ] Load testing performed
- [ ] Documentation reviewed and updated

---

## Troubleshooting Guide

### Webhook Not Received

1. Check Paystack dashboard for webhook delivery status
2. Verify webhook URL is correct and accessible
3. Check webhook signature verification
4. Review function logs for errors

### Balance Discrepancies

1. Check transaction logs for the user
2. Verify all hold/release operations are atomic
3. Look for failed transactions without balance restoration
4. Check for concurrent transaction issues

### Slow Withdrawals

1. Check Paystack API response times
2. Review function execution times
3. Look for network latency issues
4. Verify Firestore query performance

### Failed Withdrawals

1. Check Paystack error message
2. Verify user's bank account details
3. Ensure Paystack account has sufficient balance
4. Review transfer recipient validation

---

This technical guide provides a comprehensive overview of the withdrawal feature implementation. For additional support, refer to the operational runbook or contact the development team.
