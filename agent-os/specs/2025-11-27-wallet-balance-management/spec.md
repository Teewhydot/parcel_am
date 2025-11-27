# Specification: Wallet Balance Management

## Goal
Implement robust wallet balance operations (transfer between pending and normal balance, funding, withdrawal) with comprehensive protection mechanisms including duplicate detection, idempotency, and real-time processing without offline support.

## User Stories
- As a user, I want my balance operations to execute reliably so that I never lose funds due to system errors or duplicate transactions
- As a user, I want immediate feedback on my wallet operations so that I can see my balance updates in real-time

## Specific Requirements

**Transaction Idempotency with UUID-based Deduplication**
- Generate unique transaction IDs (UUID v4) client-side before initiating operations
- Store completed transaction IDs in a Firestore collection for deduplication checking
- Check for existing transaction ID before processing to prevent duplicates
- Use Firestore transactions to ensure atomic write operations
- Return existing transaction result if duplicate detected instead of re-executing
- Include idempotency key in all balance operation requests
- Set TTL on transaction records (30 days) using Firestore TTL policies
- Transaction ID format: `txn_{operationType}_{timestamp}_{uuid}`

**Real-time Connectivity Requirement**
- Leverage existing `ConnectivityService` to check internet status before operations
- Reject all balance operations when device is offline with clear error message
- Show connectivity warning in UI when offline is detected
- Do not implement offline queuing or retry mechanisms
- Use existing `NoInternetFailure` for offline error handling
- Monitor connectivity stream and disable wallet actions in UI when disconnected

**Transfer from Pending to Normal Balance (Release)**
- Deduct specified amount from `heldBalance` field
- Add same amount to `availableBalance` field
- Validate sufficient pending balance exists before operation
- Execute operation using Firestore transaction for atomicity
- Record transaction with type `TransactionType.release`
- Update `totalBalance` remains unchanged (internal transfer)
- Include reference ID linking to the source operation (e.g., delivery ID)

**Transfer from Normal to Pending Balance (Hold)**
- Deduct specified amount from `availableBalance` field
- Add same amount to `heldBalance` field
- Validate sufficient available balance exists before operation
- Execute operation using Firestore transaction for atomicity
- Record transaction with type `TransactionType.hold`
- Update `totalBalance` remains unchanged (internal transfer)
- Include reference ID linking to the purpose (e.g., escrow ID)

**Wallet Funding (Add to Balance)**
- Add specified amount to `availableBalance` field
- Increment `totalBalance` by same amount
- Record transaction with type `TransactionType.deposit`
- Include payment gateway reference ID if applicable
- Validate amount is positive before processing
- Support multiple funding sources via metadata field
- Execute using Firestore transaction for atomicity

**Wallet Withdrawal (Deduct from Balance)**
- Deduct specified amount from `availableBalance` field
- Decrement `totalBalance` by same amount
- Validate sufficient available balance before operation
- Record transaction with type `TransactionType.withdrawal`
- Include withdrawal destination reference in metadata
- Execute using Firestore transaction for atomicity
- Apply any applicable withdrawal fees (configurable)

**Enhanced Transaction Logging**
- Create transaction record in `transactions` collection for every operation
- Include fields: id, walletId, userId, amount, type, status, currency, timestamp, description, referenceId, metadata, idempotencyKey
- Add new field `idempotencyKey` to track unique transaction requests
- Store operation metadata including device info and client timestamp
- Use `TransactionStatus.pending` during processing, update to `completed` or `failed`
- Maintain audit trail with immutable transaction records
- Index transactions by userId and timestamp for efficient querying

**Firestore Atomicity and Concurrency Control**
- Use Firestore `runTransaction` for all balance-modifying operations
- Read current wallet state within transaction scope
- Perform validation checks within transaction
- Update wallet and create transaction record atomically
- Leverage Firestore's optimistic concurrency control
- Retry logic handled by Firestore SDK (up to 5 retries automatically)
- Fail entire operation if any step fails

**Error Handling for Insufficient Funds**
- Validate balance before transaction execution within atomic block
- Throw `InsufficientBalanceException` for available balance shortage
- Throw custom `InsufficientHeldBalanceException` for pending balance shortage
- Map to `ValidationFailure` at repository layer
- Display user-friendly error message with current balance and requested amount
- Do not create transaction record for failed validation

**Comprehensive Error Handling**
- Network errors: detect using existing `ConnectivityService`, return `NoInternetFailure`
- Duplicate transaction: return success with existing transaction data
- Insufficient balance: return `ValidationFailure` with balance details
- Invalid amount (negative/zero): return `ValidationFailure` before processing
- Firestore errors: wrap in `ServerFailure` with descriptive message
- Unknown errors: wrap in `UnknownFailure` with error details logged
- Transaction timeout: fail after 10 seconds, rollback changes

## Existing Code to Leverage

**WalletEntity and WalletModel**
- Already has `availableBalance`, `heldBalance`, `totalBalance` fields matching requirement terminology
- Has `lastUpdated` timestamp field for tracking modifications
- Includes currency field (currently NGN) for multi-currency support
- copyWith methods available for creating updated instances
- Firestore serialization/deserialization already implemented

**TransactionEntity and TransactionModel**
- Existing transaction types include `hold`, `release`, `deposit`, `withdrawal` matching requirements
- Transaction status enum includes `pending`, `completed`, `failed`, `cancelled`
- Has `referenceId` field for linking to external operations
- Metadata field available for storing additional context
- Firestore integration complete with timestamp handling

**WalletRemoteDataSource Implementation**
- `holdBalance` method already implements atomic Firestore transaction for moving available to held
- `releaseBalance` method already implements atomic Firestore transaction for moving held to available
- `updateBalance` method available for funding/withdrawal operations with validation
- `recordTransaction` method available for creating transaction records
- Existing validation for insufficient balance and invalid amounts
- Uses Firestore `runTransaction` for atomic operations ensuring consistency

**WalletRepository and WalletUseCase Layer**
- Repository implements Either pattern with Failure handling for all operations
- Maps domain exceptions to appropriate Failure types
- WalletUseCase delegates to repository with clean interface
- Error handling already maps InsufficientBalanceException to ValidationFailure
- Stream-based `watchBalance` available for real-time updates

**ConnectivityService for Online-only Requirement**
- `checkConnection()` method returns boolean connectivity status
- `isConnected` property for synchronous status check
- `onConnectivityChanged` stream for reactive connectivity monitoring
- Already integrated with `InternetConnectionChecker` package
- Can be injected and used before wallet operations to enforce online-only requirement

## Out of Scope
- Offline transaction queuing or caching
- Automatic retry mechanisms for failed transactions
- Multi-signature or approval workflows for transactions
- Transaction reversal/rollback UI (only automatic rollback on failure)
- External payment gateway integration details (Paystack already exists separately)
- Currency conversion or multi-currency support beyond existing currency field
- Transaction dispute resolution mechanisms
- Batch transaction processing
- Scheduled or recurring transactions
- Transaction categories or tagging beyond basic metadata
