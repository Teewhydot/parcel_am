# Specification: Wallet Withdrawal to Bank Account

## Goal
Enable users to withdraw funds from their available wallet balance to verified Nigerian bank accounts using Paystack Transfer API with comprehensive idempotency, atomic transactions, and webhook-based status tracking.

## User Stories
- As a user, I want to withdraw funds from my wallet to my bank account so that I can access my money
- As a user, I want to save multiple bank accounts so that I can quickly withdraw to my preferred account
- As a user, I want to see real-time updates on my withdrawal status so that I know when funds will arrive

## Specific Requirements

**Bank Account Verification and Management**
- Verify Nigerian bank account details using Paystack Account Resolution API before first use
- Required fields: account number (10 digits), bank code (from Paystack supported banks list)
- Display resolved account name to user for confirmation before saving
- Store verified bank accounts in Firestore `user_bank_accounts` subcollection
- Limit users to maximum 5 saved bank accounts
- Store account details: accountNumber, accountName, bankCode, bankName, recipientCode, verified, createdAt
- Use Paystack Create Transfer Recipient API to generate recipientCode on first verification
- Display list of saved accounts with bank logo, account name, masked account number
- Allow users to delete saved bank accounts (soft delete - set active=false)

**Withdrawal Amount Validation**
- Validate minimum withdrawal amount (NGN 100)
- Validate maximum single withdrawal amount (NGN 500,000)
- Check sufficient available balance before initiating withdrawal
- Display current available balance prominently in withdrawal UI
- Calculate and display any applicable fees (if configured)
- Prevent withdrawals when available balance is zero or negative
- Show clear validation messages for invalid amounts

**Withdrawal Initiation Flow**
- Generate unique withdrawal reference client-side using UUID v4 format: `WTH-{timestamp}-{uuid}`
- Check internet connectivity before allowing withdrawal (use existing ConnectivityService)
- Hold funds atomically using existing `holdBalance` method with withdrawal reference
- Create withdrawal order document in `withdrawal_orders` collection with status 'pending'
- Call Firebase Function `initiateWithdrawal` with withdrawal details
- Display loading state with "Processing withdrawal..." message
- Navigate to withdrawal status screen on successful initiation

**Paystack Transfer API Integration**
- Create new method `initiateTransfer` in payment-service.js
- Use Paystack Single Transfer API endpoint: POST /transfer
- Required parameters: source='balance', amount (in kobo), recipient (recipientCode), reference, reason
- Set transfer source to 'balance' (funds from Paystack account balance)
- Include metadata with userId, userName, withdrawalOrderId
- Implement idempotency using unique withdrawal reference
- Handle Paystack API errors: insufficient balance, invalid recipient, network errors
- Log all API calls with comprehensive request/response details

**Withdrawal Order Management**
- Create withdrawal order in `withdrawal_orders` collection before transfer
- Fields: id (withdrawal reference), userId, amount, bankAccount (embedded), status, recipientCode, transferCode, createdAt, updatedAt, processedAt, metadata
- Status values: 'pending', 'processing', 'success', 'failed', 'reversed'
- Update status to 'processing' when Paystack transfer initiated
- Store Paystack transferCode from API response
- Create transaction record with type `TransactionType.withdrawal` and status 'pending'
- Link withdrawal order to transaction using referenceId

**Webhook Handler for Transfer Status**
- Create new webhook event handlers for transfer events in paystackWebhook function
- Handle event types: 'transfer.success', 'transfer.failed', 'transfer.reversed'
- Verify webhook signature using existing verifyWebhookSignature method
- Implement deduplication using processed_webhooks collection (same pattern as existing)
- Extract transfer data: transferCode, reference, status, amount, recipient, reason

**Transfer Success Processing**
- Update withdrawal order status to 'success'
- Deduct held balance atomically (funds already held during initiation)
- Update transaction status to 'completed'
- Record processedAt timestamp
- Send success notification to user with withdrawal details
- Include bank account name and expected arrival time in notification

**Transfer Failure Processing**
- Update withdrawal order status to 'failed'
- Release held funds back to available balance using existing `releaseBalance` method
- Update transaction status to 'failed'
- Store failure reason from Paystack response
- Send failure notification to user with reason
- Allow user to retry withdrawal from transaction history

**Transfer Reversal Processing**
- Update withdrawal order status to 'reversed'
- Release held funds back to available balance atomically
- Create reversal transaction record with type `TransactionType.refund`
- Update original transaction status to 'cancelled'
- Send reversal notification to user explaining the reversal
- Include reversal reason from Paystack webhook data

**Atomic Balance Operations**
- Use Firestore runTransaction for all balance modifications
- Hold funds during initiation: available balance → held balance
- On success: held balance → deducted (reduce totalBalance)
- On failure/reversal: held balance → available balance (restore)
- Validate balance state at each transaction step
- Implement retry logic (Firestore SDK automatic retries)
- Rollback entire operation if any step fails

**Idempotency Implementation**
- Client generates withdrawal reference before API call
- Firebase Function checks for existing withdrawal order with same reference
- Return existing order status if duplicate request detected
- Paystack uses reference for its own idempotency (won't duplicate transfers)
- Store processed webhook event IDs to prevent duplicate webhook processing
- Use same TTL pattern as existing webhooks (7 days auto-delete)

**Transaction History Integration**
- Display withdrawal transactions in existing transaction history screen
- Show withdrawal icon, amount, bank account name, status
- Filter by transaction type 'withdrawal' in existing getTransactions method
- Support search by withdrawal reference or bank account name
- Show detailed withdrawal information on tap: bank details, status, timestamps
- Allow retry for failed withdrawals from transaction detail screen

**Error Handling and User Feedback**
- Network errors: Show "No internet connection" error, retry option
- Insufficient balance: Show current balance vs requested amount, clear message
- Invalid bank details: Show verification error, prompt to re-enter
- Paystack API errors: Map error codes to user-friendly messages
- Transfer failures: Show failure reason from Paystack, support contact option
- Timeout errors: Show "Request taking longer than expected", check status option
- Unknown errors: Log to Firebase, show generic error with reference number

**Security and Validation**
- Require PIN or biometric authentication before withdrawal confirmation
- Validate user owns the wallet being withdrawn from
- Rate limit withdrawal requests: maximum 5 per hour per user
- Log all withdrawal attempts with IP address and device info
- Encrypt bank account details at rest (use Firestore encryption)
- Never expose full account numbers in logs or error messages
- Validate all amounts are positive and within allowed range
- Check for suspicious patterns (multiple failures, rapid requests)

**Real-time Status Updates**
- Use Firestore snapshots to watch withdrawal order status changes
- Update UI immediately when webhook processes transfer status
- Show status badge: Pending (yellow), Processing (blue), Success (green), Failed (red)
- Display progress indicator during processing
- Auto-refresh transaction list when new webhook updates arrive
- Show push notification for status changes when app is background

**Performance and Scalability**
- Index withdrawal_orders collection by userId and createdAt
- Index withdrawal_orders by status for admin queries
- Set TTL on completed withdrawals (90 days retention)
- Paginate withdrawal history using existing pagination pattern
- Cache bank list from Paystack (refresh daily)
- Optimize Firestore reads using compound queries
- Implement Firebase Function timeout of 60 seconds for withdrawal initiation

**Nigerian Bank Integration**
- Fetch list of Nigerian banks from Paystack List Banks API
- Cache bank list in Firestore `system_config/banks` document
- Refresh bank list daily using scheduled Cloud Function
- Display banks with logos (use bank code to logo mapping)
- Support bank search by name in account verification UI
- Handle bank code changes (update cached data on verification failure)

## Existing Code to Leverage

**WalletRemoteDataSource balance operations**
- Use existing `holdBalance` method to hold funds during withdrawal initiation
- Use existing `releaseBalance` method to restore funds on failure/reversal
- Use existing `updateBalance` method pattern for final balance deduction
- Leverage existing idempotency check with `_checkDuplicateTransaction`
- Follow existing atomic transaction pattern with Firestore runTransaction

**Payment Service integration patterns**
- Replicate `initializeTransaction` pattern for `initiateTransfer` method
- Use existing axios configuration with Bearer token authentication
- Follow existing error handling with try-catch and detailed logging
- Use existing logger utility for comprehensive API call logging
- Implement same retry pattern with exponential backoff

**Webhook processing infrastructure**
- Extend existing paystackWebhook function with transfer event handlers
- Use existing `verifyWebhookSignature` for webhook authentication
- Follow existing deduplication pattern with processed_webhooks collection
- Replicate existing atomic transaction pattern for status updates
- Use existing notification integration for user alerts

**Transaction and wallet models**
- Transaction entity already has 'withdrawal' type in TransactionType enum
- Transaction status enum includes all needed states (pending, completed, failed)
- Wallet model has availableBalance and heldBalance fields for hold/release pattern
- Existing referenceId field links transactions to withdrawal orders
- Metadata field available for storing withdrawal-specific details

**Database helper utilities**
- Use existing `dbHelper.getDocument` for fetching withdrawal orders
- Use existing `dbHelper.updateDocument` for status updates
- Use existing `dbHelper.addDocument` for creating withdrawal records
- Follow existing `dbHelper.getServerTimestamp()` for consistent timestamps
- Leverage existing compound query helpers for transaction filtering

## Out of Scope
- International bank transfers (only Nigerian banks)
- Scheduled or recurring withdrawals
- Withdrawal to mobile money wallets
- Currency conversion (only NGN)
- Withdrawal limits per day/week/month (only per-transaction limits)
- Withdrawal fee configuration UI (use hard-coded fee if needed)
- Bank account ownership verification beyond Paystack verification
- Withdrawal dispute resolution workflow
- Admin panel for managing withdrawals
- Batch withdrawals or CSV import
