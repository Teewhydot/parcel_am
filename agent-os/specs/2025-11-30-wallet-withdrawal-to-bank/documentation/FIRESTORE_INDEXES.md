# Firestore Indexes for Wallet Withdrawal Feature

## Overview
This document lists all Firestore composite indexes required for the wallet withdrawal feature to function efficiently.

## Critical: Deploy These Indexes Before Production

All indexes listed below MUST be created in Firestore before deploying the withdrawal feature to production. Without these indexes, queries will fail or perform poorly.

---

## Composite Indexes

### 1. Withdrawal Orders - User Query

**Collection:** `withdrawal_orders`

**Purpose:** Query user's withdrawal orders sorted by time

**Fields:**
- `userId` (Ascending)
- `createdAt` (Descending)

**Query Example:**
```javascript
db.collection('withdrawal_orders')
  .where('userId', '==', userId)
  .orderBy('createdAt', 'desc')
  .limit(20)
```

**Firebase Console Format:**
```json
{
  "collectionGroup": "withdrawal_orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

### 2. Withdrawal Orders - Status Query

**Collection:** `withdrawal_orders`

**Purpose:** Monitor withdrawals by status (for admin/monitoring dashboards)

**Fields:**
- `status` (Ascending)
- `createdAt` (Descending)

**Query Example:**
```javascript
db.collection('withdrawal_orders')
  .where('status', '==', 'pending')
  .orderBy('createdAt', 'desc')
```

**Firebase Console Format:**
```json
{
  "collectionGroup": "withdrawal_orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

### 3. Withdrawal Orders - User and Status Query

**Collection:** `withdrawal_orders`

**Purpose:** Filter user's withdrawals by status

**Fields:**
- `userId` (Ascending)
- `status` (Ascending)
- `createdAt` (Descending)

**Query Example:**
```javascript
db.collection('withdrawal_orders')
  .where('userId', '==', userId)
  .where('status', '==', 'failed')
  .orderBy('createdAt', 'desc')
```

**Firebase Console Format:**
```json
{
  "collectionGroup": "withdrawal_orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

### 4. Transactions - Type Filter

**Collection:** `transactions`

**Purpose:** Filter transactions by type (withdrawal, deposit, etc.)

**Fields:**
- `walletId` (Ascending)
- `type` (Ascending)
- `timestamp` (Descending)

**Query Example:**
```javascript
db.collection('transactions')
  .where('walletId', '==', walletId)
  .where('type', '==', 'withdrawal')
  .orderBy('timestamp', 'desc')
```

**Firebase Console Format:**
```json
{
  "collectionGroup": "transactions",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "walletId", "order": "ASCENDING" },
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

---

### 5. User Bank Accounts - Active Accounts

**Collection:** `user_bank_accounts` (subcollection)

**Purpose:** Query user's active bank accounts

**Fields:**
- `userId` (Ascending)
- `active` (Ascending)
- `createdAt` (Descending)

**Query Example:**
```javascript
db.collectionGroup('user_bank_accounts')
  .where('userId', '==', userId)
  .where('active', '==', true)
  .orderBy('createdAt', 'desc')
```

**Firebase Console Format:**
```json
{
  "collectionGroup": "user_bank_accounts",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "active", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

### 6. Audit Logs - Withdrawal Attempts

**Collection:** `audit_logs`

**Purpose:** Query withdrawal attempts for security monitoring

**Fields:**
- `type` (Ascending)
- `userId` (Ascending)
- `timestamp` (Descending)

**Query Example:**
```javascript
db.collection('audit_logs')
  .where('type', '==', 'withdrawal_attempt')
  .where('userId', '==', userId)
  .orderBy('timestamp', 'desc')
```

**Firebase Console Format:**
```json
{
  "collectionGroup": "audit_logs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

---

## How to Create Indexes

### Method 1: Firebase Console (Recommended for Testing)

1. Go to Firebase Console
2. Select your project
3. Navigate to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index"
6. Enter the collection name
7. Add fields with specified order
8. Click "Create Index"
9. Wait for index to build (can take several minutes)

### Method 2: Firebase CLI (Recommended for Production)

Create a file `firestore.indexes.json` in your Firebase project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "withdrawal_orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "withdrawal_orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "withdrawal_orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "walletId", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "user_bank_accounts",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "active", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "audit_logs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy using Firebase CLI:

```bash
firebase deploy --only firestore:indexes
```

### Method 3: Automatic Creation via Error Messages

When you run a query that requires an index, Firestore will provide an error message with a link to automatically create the index. However, this method is NOT recommended for production deployment.

---

## TTL Policies

Configure Time-To-Live (TTL) policies to automatically delete old documents:

### 1. Withdrawal Orders TTL (90 days)

**Collection:** `withdrawal_orders`

**Field:** `createdAt`

**TTL:** 90 days

**How to Set Up:**
1. Go to Firestore Console
2. Select `withdrawal_orders` collection
3. Click "TTL Policy"
4. Select field: `createdAt`
5. Set expiration: 90 days
6. Save

### 2. Processed Webhooks TTL (7 days)

**Collection:** `processed_webhooks`

**Field:** `processedAt`

**TTL:** 7 days

**Purpose:** Prevent duplicate webhook processing while cleaning up old entries

### 3. Audit Logs TTL (365 days)

**Collection:** `audit_logs`

**Field:** `timestamp`

**TTL:** 365 days

**Purpose:** Maintain security logs for 1 year, then auto-delete

---

## Verification Checklist

Before deploying to production, verify:

- [ ] All 6 composite indexes created
- [ ] All indexes show "Enabled" status (not "Building")
- [ ] TTL policies configured for:
  - [ ] withdrawal_orders (90 days)
  - [ ] processed_webhooks (7 days)
  - [ ] audit_logs (365 days)
- [ ] Test queries execute successfully without errors
- [ ] No "index required" errors in development logs

---

## Performance Monitoring

After deployment, monitor:

1. **Query Performance**
   - Average query execution time
   - Should be < 100ms for most queries

2. **Index Usage**
   - Check Firebase Console > Firestore > Usage
   - Verify indexes are being used

3. **Read Operations**
   - Monitor read operation count
   - Ensure pagination is working to limit reads

4. **Index Build Time**
   - New indexes on large collections may take time to build
   - Plan index creation during low-traffic periods

---

## Troubleshooting

### "Index Required" Error

**Symptom:**
```
The query requires an index. You can create it here: [link]
```

**Solution:**
1. Click the provided link to create the index
2. Or manually create using the specifications above
3. Wait for index to finish building
4. Retry the query

### Slow Queries

**Symptom:**
Queries taking >1 second to execute

**Possible Causes:**
1. Index not created or still building
2. Large result set (not using pagination)
3. Complex compound queries

**Solutions:**
1. Verify index status in console
2. Implement pagination (limit query results)
3. Consider denormalization for frequently accessed data

### Index Building Takes Too Long

**Symptom:**
Index stuck in "Building" state for >30 minutes

**Solutions:**
1. Check collection size (large collections take longer)
2. Verify no ongoing writes to the collection
3. If stuck >1 hour, contact Firebase support
4. Consider creating index during low-traffic period

---

## Notes

- Indexes are automatically maintained by Firestore
- New documents are automatically indexed
- Deleting an index does not delete data
- Unused indexes can be deleted to reduce storage costs
- Maximum 200 composite indexes per project (we're using 6)

---

## Deployment Checklist

**Pre-Deployment:**
- [ ] Review all indexes
- [ ] Create indexes in staging environment
- [ ] Test all queries in staging
- [ ] Verify index performance
- [ ] Document index creation in deployment notes

**Deployment:**
- [ ] Deploy indexes before deploying code
- [ ] Wait for all indexes to finish building
- [ ] Test critical queries
- [ ] Monitor error logs for missing indexes

**Post-Deployment:**
- [ ] Verify all queries working
- [ ] Monitor query performance
- [ ] Check Firestore usage metrics
- [ ] Set up alerts for index-related errors

---

## Contact

For issues with index creation or performance:
- Firebase Support: https://firebase.google.com/support
- Internal: Contact DevOps team

---

**Last Updated:** 2025-11-30
**Review Date:** 2026-02-28 (Quarterly review recommended)
