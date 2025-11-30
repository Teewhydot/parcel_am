# Wallet Withdrawal Operational Runbook

## Overview
This runbook provides operational procedures for monitoring, troubleshooting, and managing the wallet withdrawal feature in production.

## Table of Contents
1. [Monitoring Dashboard](#monitoring-dashboard)
2. [Common Operational Tasks](#common-operational-tasks)
3. [Incident Response](#incident-response)
4. [Manual Interventions](#manual-interventions)
5. [Webhook Management](#webhook-management)
6. [Balance Reconciliation](#balance-reconciliation)
7. [User Support Procedures](#user-support-procedures)
8. [Escalation Paths](#escalation-paths)

---

## Monitoring Dashboard

### Key Metrics to Monitor

**Real-Time Metrics (check every hour during business hours)**
- Active withdrawals (pending/processing) count
- Withdrawal success rate (last 1 hour)
- Withdrawal failure rate (last 1 hour)
- Average processing time
- Webhook processing delays

**Daily Metrics**
- Total withdrawal volume (count and NGN amount)
- Failure rate by reason
- Reversal rate
- User withdrawal statistics
- Rate limit hit count

### Firestore Queries for Monitoring

```javascript
// Get all pending/processing withdrawals
db.collection('withdrawal_orders')
  .where('status', 'in', ['pending', 'processing'])
  .orderBy('createdAt', 'desc')
  .get()

// Get failed withdrawals in last 24 hours
const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
db.collection('withdrawal_orders')
  .where('status', '==', 'failed')
  .where('createdAt', '>=', oneDayAgo)
  .get()

// Get slow-processing withdrawals (>30 minutes in processing)
const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
db.collection('withdrawal_orders')
  .where('status', '==', 'processing')
  .where('updatedAt', '<=', thirtyMinutesAgo)
  .get()
```

### Alerts to Configure

**Critical Alerts (immediate response required)**
- Withdrawal failure rate > 10% in last hour
- No successful withdrawals in last 2 hours (during business hours)
- Webhook processing failure rate > 5%
- Firebase Function errors > 20 in last hour

**Warning Alerts (investigate within 1 hour)**
- Withdrawal failure rate > 5% in last hour
- Average processing time > 30 minutes
- More than 10 withdrawals stuck in "processing" for >1 hour
- Paystack API latency > 5 seconds

**Info Alerts (investigate during business hours)**
- Unusual withdrawal volume spike (>200% of daily average)
- High rate limit hit count (>50 users/day)
- Bank list cache refresh failure

---

## Common Operational Tasks

### 1. Daily Health Check (Every Morning)

```bash
# Run these queries in Firestore console or via script

# 1. Check for stuck withdrawals (>24 hours old, still processing)
db.collection('withdrawal_orders')
  .where('status', 'in', ['pending', 'processing'])
  .where('createdAt', '<=', new Date(Date.now() - 24 * 60 * 60 * 1000))
  .get()

# 2. Review failed withdrawals from yesterday
const yesterday = new Date();
yesterday.setDate(yesterday.getDate() - 1);
yesterday.setHours(0, 0, 0, 0);

db.collection('withdrawal_orders')
  .where('status', '==', 'failed')
  .where('createdAt', '>=', yesterday)
  .get()

# 3. Check success rate from yesterday
# Calculate: (success_count / total_count) * 100
# Target: > 95%

# 4. Review audit logs for suspicious activity
db.collection('audit_logs')
  .where('type', '==', 'withdrawal_attempt')
  .where('status', '==', 'blocked')
  .where('timestamp', '>=', yesterday)
  .get()

# 5. Verify bank list is up-to-date
db.collection('system_config')
  .doc('banks')
  .get()
  .then(doc => {
    const lastUpdated = doc.data().lastUpdated.toDate();
    const hoursSinceUpdate = (Date.now() - lastUpdated) / (60 * 60 * 1000);
    if (hoursSinceUpdate > 25) {
      console.warn('Bank list not updated in last 24 hours');
    }
  })
```

### 2. Weekly Review (Every Monday)

1. **Generate Weekly Report**
   - Total withdrawals (count and volume)
   - Success rate
   - Failure breakdown by reason
   - Reversal count and reasons
   - Top users by withdrawal volume
   - Average processing time trend

2. **Review Paystack Dashboard**
   - Transfer volume and trends
   - Failed transfers analysis
   - Balance utilization

3. **Capacity Planning**
   - Review withdrawal volume trends
   - Project growth
   - Assess Paystack balance needs

### 3. Monthly Tasks

1. **Security Audit**
   - Review suspicious activity logs
   - Check for unusual patterns
   - Verify rate limiting effectiveness

2. **Performance Review**
   - Analyze processing time trends
   - Identify bottlenecks
   - Review Firestore query performance

3. **Cost Analysis**
   - Firebase Functions usage and cost
   - Firestore read/write operations
   - Paystack transfer fees

---

## Incident Response

### Incident: High Withdrawal Failure Rate

**Symptoms:**
- Sudden spike in failed withdrawals (>10%)
- Users reporting withdrawal failures

**Immediate Actions:**
1. Check Paystack service status: https://status.paystack.com
2. Review recent failed withdrawals for common error messages
3. Check Firebase Functions logs for errors

**Investigation:**
```bash
# Get recent failed withdrawals with reasons
db.collection('withdrawal_orders')
  .where('status', '==', 'failed')
  .where('createdAt', '>=', new Date(Date.now() - 60 * 60 * 1000))
  .get()
  .then(snapshot => {
    const failures = {};
    snapshot.forEach(doc => {
      const reason = doc.data().failureReason || 'Unknown';
      failures[reason] = (failures[reason] || 0) + 1;
    });
    console.log(failures);
  })
```

**Resolution Paths:**

**If Paystack API Issue:**
1. Check Paystack status page
2. Contact Paystack support if needed
3. Communicate estimated resolution time to users
4. Monitor for service restoration

**If Insufficient Paystack Balance:**
1. Check Paystack dashboard balance
2. Top up Paystack balance immediately
3. Failed withdrawals can be retried by users once balance restored

**If Invalid Recipient Errors:**
1. Check if specific bank is affected
2. Verify bank account validation is working
3. May need to refresh bank list or contact Paystack

**If Function Errors:**
1. Review Cloud Function logs
2. Check for code deployment issues
3. Roll back to previous version if needed
4. Fix and redeploy

### Incident: Webhooks Not Processing

**Symptoms:**
- Withdrawals stuck in "processing" status
- No status updates for extended period

**Immediate Actions:**
1. Check webhook endpoint accessibility
2. Review Firebase Functions logs for webhook handler errors
3. Check Paystack webhook delivery attempts in dashboard

**Investigation:**
```bash
# Check for withdrawals stuck in processing
db.collection('withdrawal_orders')
  .where('status', '==', 'processing')
  .where('updatedAt', '<=', new Date(Date.now() - 30 * 60 * 1000))
  .get()

# Check webhook handler logs
# Filter Cloud Function logs by function name: paystackWebhook
# Look for errors in last 1-2 hours
```

**Resolution:**

**If Webhook Endpoint Down:**
1. Verify Firebase Functions are running
2. Check for deployment issues
3. Redeploy if necessary
4. Manually replay missed webhooks (see manual intervention section)

**If Webhook Signature Verification Failing:**
1. Verify PAYSTACK_SECRET_KEY environment variable
2. Check for key rotation on Paystack side
3. Update key if needed
4. Redeploy function

**If Processing Errors:**
1. Review error logs for specific failure
2. Fix code issue
3. Redeploy
4. Manually process affected withdrawals (see manual intervention)

### Incident: Balance Discrepancies

**Symptoms:**
- User reports incorrect wallet balance
- Withdrawal succeeded but balance not deducted
- Withdrawal failed but balance not restored

**Immediate Actions:**
1. Stop processing new withdrawals (if widespread)
2. Get affected user's transaction history
3. Review audit logs for the user

**Investigation:**
```bash
# Get user's wallet state
db.collection('users')
  .doc(userId)
  .collection('wallet')
  .doc(userId)
  .get()

# Get user's withdrawal orders
db.collection('withdrawal_orders')
  .where('userId', '==', userId)
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get()

# Get user's transactions
db.collection('transactions')
  .where('userId', '==', userId)
  .where('type', 'in', ['withdrawal', 'hold', 'release'])
  .orderBy('timestamp', 'desc')
  .limit(50)
  .get()
```

**Resolution:**
1. Calculate expected balance based on transaction history
2. Identify missing/incorrect balance operation
3. Manually correct balance (see manual intervention section)
4. Log incident for root cause analysis
5. Fix underlying code issue if identified

---

## Manual Interventions

### Manually Process Missed Webhook

**Scenario:** Webhook was not received or failed to process

**Procedure:**
1. Get withdrawal order details from Firestore
2. Verify transfer status on Paystack dashboard
3. Manually update withdrawal order and user balance

```javascript
// Script: manual_webhook_processing.js

const admin = require('firebase-admin');
const { getWithdrawalOrder, processTransferSuccess } = require('./helpers');

async function manuallyProcessWebhook(withdrawalReference, paystackTransferCode) {
  const executionId = `manual-webhook-${Date.now()}`;

  try {
    // 1. Get withdrawal order
    const withdrawalOrder = await getWithdrawalOrder(withdrawalReference);
    if (!withdrawalOrder) {
      throw new Error('Withdrawal order not found');
    }

    // 2. Verify status on Paystack (manual check)
    console.log('Verify transfer status on Paystack dashboard:');
    console.log(`Transfer Code: ${paystackTransferCode}`);
    console.log('Confirm status before proceeding...');

    const status = prompt('Enter status (success/failed/reversed): ');

    // 3. Process based on status
    if (status === 'success') {
      await processTransferSuccess({
        reference: withdrawalReference,
        transfer_code: paystackTransferCode,
        amount: withdrawalOrder.amount,
      }, executionId);

      console.log('✅ Success webhook processed manually');
    } else if (status === 'failed') {
      const reason = prompt('Enter failure reason: ');
      await processTransferFailed({
        reference: withdrawalReference,
        transfer_code: paystackTransferCode,
        failureReason: reason,
      }, executionId);

      console.log('✅ Failure webhook processed manually');
    } else if (status === 'reversed') {
      const reason = prompt('Enter reversal reason: ');
      await processTransferReversed({
        reference: withdrawalReference,
        transfer_code: paystackTransferCode,
        reversalReason: reason,
      }, executionId);

      console.log('✅ Reversal webhook processed manually');
    }

  } catch (error) {
    console.error('❌ Manual processing failed:', error);
  }
}

// Usage
manuallyProcessWebhook('WTH-1234567890-abc123', 'TRF_xyz789');
```

### Manually Correct User Balance

**Scenario:** Balance is incorrect due to failed transaction processing

**Procedure:**

```javascript
// Script: correct_user_balance.js

async function correctUserBalance(userId, correction) {
  const executionId = `manual-balance-correction-${Date.now()}`;

  try {
    await admin.firestore().runTransaction(async (transaction) => {
      const walletRef = admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('wallet')
        .doc(userId);

      const walletDoc = await transaction.get(walletRef);
      const wallet = walletDoc.data();

      // Log current state
      console.log('Current balance:', wallet);

      // Apply correction
      const newAvailableBalance = wallet.availableBalance + correction.availableBalanceChange;
      const newHeldBalance = wallet.heldBalance + correction.heldBalanceChange;
      const newTotalBalance = wallet.totalBalance + correction.totalBalanceChange;

      transaction.update(walletRef, {
        availableBalance: newAvailableBalance,
        heldBalance: newHeldBalance,
        totalBalance: newTotalBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log correction in audit trail
      await admin.firestore().collection('audit_logs').add({
        type: 'manual_balance_correction',
        userId,
        executionId,
        correction,
        previousState: wallet,
        newState: {
          availableBalance: newAvailableBalance,
          heldBalance: newHeldBalance,
          totalBalance: newTotalBalance,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        operator: 'admin', // Or specific admin user ID
      });
    });

    console.log('✅ Balance corrected successfully');
  } catch (error) {
    console.error('❌ Balance correction failed:', error);
  }
}

// Example usage
correctUserBalance('user123', {
  availableBalanceChange: 5000,  // Add 5000 to available
  heldBalanceChange: -5000,      // Remove 5000 from held
  totalBalanceChange: 0,         // No change to total
});
```

### Retry Failed Paystack Transfer

**Scenario:** Transfer failed but can be retried (e.g., temporary Paystack issue)

**Procedure:**
1. User should retry via app (preferred)
2. If manual retry needed:

```javascript
// Script: retry_failed_transfer.js

async function retryFailedTransfer(withdrawalReference) {
  const executionId = `retry-transfer-${Date.now()}`;

  try {
    // 1. Get original withdrawal order
    const originalOrder = await getWithdrawalOrder(withdrawalReference);
    if (originalOrder.status !== 'failed') {
      throw new Error('Withdrawal is not in failed status');
    }

    // 2. Create new withdrawal reference
    const newReference = generateWithdrawalReference();

    // 3. Initiate new withdrawal with same details
    const result = await initiateWithdrawal({
      userId: originalOrder.userId,
      amount: originalOrder.amount,
      recipientCode: originalOrder.recipientCode,
      withdrawalReference: newReference,
      bankAccountId: originalOrder.metadata.bankAccountId,
    });

    // 4. Link to original
    await admin.firestore()
      .collection('withdrawal_orders')
      .doc(newReference)
      .update({
        metadata: {
          ...result.metadata,
          retryOf: withdrawalReference,
        },
      });

    console.log('✅ Transfer retried successfully');
    console.log('New reference:', newReference);

    return result;
  } catch (error) {
    console.error('❌ Retry failed:', error);
  }
}
```

---

## Webhook Management

### Replay Missed Webhooks

**Using Paystack Dashboard:**
1. Login to Paystack dashboard
2. Go to Settings > Webhooks
3. Find the webhook event
4. Click "Replay Event"

**Using Paystack API:**
```javascript
const axios = require('axios');

async function replayWebhook(eventId) {
  try {
    const response = await axios.post(
      `https://api.paystack.co/webhook/replay/${eventId}`,
      {},
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
        },
      }
    );

    console.log('Webhook replayed:', response.data);
  } catch (error) {
    console.error('Failed to replay webhook:', error);
  }
}
```

### Test Webhook Endpoint

```bash
# Test webhook endpoint accessibility
curl -X POST https://your-region-your-project.cloudfunctions.net/paystackWebhook \
  -H "Content-Type: application/json" \
  -H "x-paystack-signature: test" \
  -d '{"event": "test"}'

# Should return 200 OK
```

---

## Balance Reconciliation

### Daily Reconciliation Check

Run daily to ensure balances match transaction history:

```javascript
// Script: daily_reconciliation.js

async function dailyReconciliation() {
  const users = await admin.firestore().collection('users').get();

  for (const userDoc of users.docs) {
    const userId = userDoc.id;

    // Get current wallet state
    const walletDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('wallet')
      .doc(userId)
      .get();

    if (!walletDoc.exists) continue;

    const wallet = walletDoc.data();

    // Get all transactions
    const transactions = await admin.firestore()
      .collection('transactions')
      .where('userId', '==', userId)
      .get();

    // Calculate expected balance
    let expectedAvailable = 0;
    let expectedHeld = 0;
    let expectedTotal = 0;

    transactions.forEach(tx => {
      const data = tx.data();
      const amount = data.amount;

      switch (data.type) {
        case 'deposit':
          if (data.status === 'completed') {
            expectedAvailable += amount;
            expectedTotal += amount;
          }
          break;
        case 'withdrawal':
          if (data.status === 'pending' || data.status === 'processing') {
            expectedHeld += amount;
          } else if (data.status === 'completed') {
            expectedTotal -= amount;
          }
          break;
        case 'hold':
          expectedAvailable -= amount;
          expectedHeld += amount;
          break;
        case 'release':
          expectedAvailable += amount;
          expectedHeld -= amount;
          break;
      }
    });

    // Compare with actual
    const availableDiff = Math.abs(wallet.availableBalance - expectedAvailable);
    const heldDiff = Math.abs(wallet.heldBalance - expectedHeld);
    const totalDiff = Math.abs(wallet.totalBalance - expectedTotal);

    if (availableDiff > 1 || heldDiff > 1 || totalDiff > 1) {
      console.warn(`Discrepancy found for user ${userId}:`);
      console.warn(`Expected: available=${expectedAvailable}, held=${expectedHeld}, total=${expectedTotal}`);
      console.warn(`Actual: available=${wallet.availableBalance}, held=${wallet.heldBalance}, total=${wallet.totalBalance}`);

      // Log for manual review
      await admin.firestore().collection('reconciliation_alerts').add({
        userId,
        expected: { expectedAvailable, expectedHeld, expectedTotal },
        actual: {
          availableBalance: wallet.availableBalance,
          heldBalance: wallet.heldBalance,
          totalBalance: wallet.totalBalance,
        },
        differences: { availableDiff, heldDiff, totalDiff },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  console.log('✅ Reconciliation complete');
}
```

---

## User Support Procedures

### Withdrawal Status Inquiry

**User asks:** "Where is my withdrawal?"

**Steps:**
1. Get withdrawal reference from user
2. Look up withdrawal order in Firestore
3. Check current status
4. Provide appropriate response based on status

**Script:**
```javascript
async function checkWithdrawalStatus(withdrawalReference) {
  const doc = await admin.firestore()
    .collection('withdrawal_orders')
    .doc(withdrawalReference)
    .get();

  if (!doc.exists) {
    return 'Withdrawal not found. Please verify the reference.';
  }

  const withdrawal = doc.data();

  switch (withdrawal.status) {
    case 'pending':
      return 'Your withdrawal is pending processing. It should be processed shortly.';

    case 'processing':
      const processingTime = Date.now() - withdrawal.updatedAt.toMillis();
      const minutesProcessing = Math.floor(processingTime / 60000);
      return `Your withdrawal is currently processing (${minutesProcessing} minutes). Bank transfers typically complete within 15-30 minutes.`;

    case 'success':
      return `Your withdrawal was successful on ${withdrawal.processedAt.toDate().toLocaleString()}. Please allow up to 24 hours for your bank to credit the funds.`;

    case 'failed':
      return `Your withdrawal failed. Reason: ${withdrawal.failureReason}. Funds have been returned to your wallet. You can retry the withdrawal.`;

    case 'reversed':
      return `Your withdrawal was reversed by the bank. Reason: ${withdrawal.reversalReason}. Funds have been returned to your wallet.`;

    default:
      return 'Unknown status. Please contact technical support.';
  }
}
```

### Withdrawal Taking Too Long

**User asks:** "My withdrawal has been processing for hours"

**Steps:**
1. Check withdrawal order status
2. If still "processing":
   - Check Paystack dashboard for transfer status
   - Compare Firestore status with Paystack status
   - If mismatch, webhook may have been missed
   - Manually process webhook if needed

### Funds Not in Bank Account

**User asks:** "Withdrawal shows success but I haven't received funds"

**Steps:**
1. Confirm withdrawal is marked "success" in Firestore
2. Verify transfer_code in withdrawal order
3. Check transfer status on Paystack dashboard
4. Confirm expected arrival time (up to 24 hours)
5. If Paystack shows success and >24 hours:
   - Ask user to contact their bank
   - Provide transfer reference and date
   - Bank can trace the transfer

### Want to Cancel Withdrawal

**User asks:** "Can I cancel my withdrawal?"

**Response:**
- Withdrawals cannot be cancelled once initiated
- If status is "pending" or "processing", funds are already being transferred
- If transfer fails, funds will be automatically returned to wallet
- User can then withdraw to a different account if needed

---

## Escalation Paths

### Level 1: First-Line Support
**Handles:**
- Status inquiries
- General questions
- Account verification issues
- Simple troubleshooting

**Escalate to Level 2 if:**
- Balance discrepancy reported
- Withdrawal stuck for >2 hours
- Multiple failures for same user
- Technical errors

### Level 2: Technical Support
**Handles:**
- Investigate stuck withdrawals
- Review logs for errors
- Manual webhook processing
- Balance corrections (with approval)

**Escalate to Level 3 if:**
- Widespread system issue
- Paystack integration problem
- Code bug identified
- Security concern

### Level 3: Engineering Team
**Handles:**
- Code fixes and deployments
- Paystack API issues
- Architecture changes
- Security incidents

**Escalate to Level 4 if:**
- Critical production outage
- Data loss risk
- Security breach
- Paystack service outage

### Level 4: Management/Paystack Support
**Handles:**
- Critical business decisions
- Paystack account issues
- Major incident coordination
- External communications

---

## Emergency Contacts

**Paystack Support:**
- Email: support@paystack.com
- Phone: +234 (0) 1 888 0000

**Internal Contacts:**
- Engineering Lead: [Contact Info]
- DevOps: [Contact Info]
- Product Manager: [Contact Info]
- Customer Support Manager: [Contact Info]

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-11-30 | Initial runbook created | Development Team |

---

**Remember:**
- Always log manual interventions
- Document unusual incidents for future reference
- Update this runbook as new issues are discovered
- Review and refine procedures quarterly
