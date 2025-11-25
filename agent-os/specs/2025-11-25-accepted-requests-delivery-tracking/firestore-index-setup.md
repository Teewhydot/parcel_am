# Firestore Composite Index Setup Guide

## Overview

This guide provides step-by-step instructions for creating the Firestore composite indexes required for the Accepted Requests Delivery Tracking feature. These indexes enable efficient querying of parcels by traveler ID and sorting by recent status updates.

## Required Indexes

### Primary Index: Traveler Deliveries by Recent Activity

**Purpose:** Efficiently query parcels assigned to a specific courier, sorted by most recent status updates.

**Index Configuration:**
- **Collection:** `parcels`
- **Fields:**
  1. `travelerId` (Ascending)
  2. `lastStatusUpdate` (Descending)
- **Query Scope:** Collection

**Use Case:** Powers the "My Deliveries" tab, showing courier's active and completed deliveries ordered by most recently updated first.

**Query Performance Expectations:**
- With index: < 100ms for 1000+ documents
- Without index: Query will fail with "index required" error

---

## Method 1: Create Index via Firebase Console (UI)

### Prerequisites
- Access to Firebase Console
- Owner, Editor, or Firebase Admin role on the project

### Step-by-Step Instructions

1. **Navigate to Firebase Console**
   - Open https://console.firebase.google.com/
   - Select your project (e.g., "Parcel AM")

2. **Access Firestore Database**
   - In the left sidebar, click "Firestore Database"
   - You should see your Firestore data and navigation tabs

3. **Open Indexes Tab**
   - Click the "Indexes" tab at the top of the Firestore page
   - You'll see two sections: "Single field" and "Composite"
   - Click on the "Composite" tab

4. **Create New Composite Index**
   - Click the "+ Create Index" button
   - You'll be taken to the index creation form

5. **Configure Index Fields**
   - **Collection ID:** Enter `parcels`
   - **Query Scope:** Select "Collection" (not "Collection group")

6. **Add First Field**
   - **Field path:** Enter `travelerId`
   - **Query scope:** Select "Ascending" from the dropdown
   - This field filters parcels by the courier's user ID

7. **Add Second Field**
   - Click "+ Add field" button
   - **Field path:** Enter `lastStatusUpdate`
   - **Query scope:** Select "Descending" from the dropdown
   - This field sorts parcels by most recent status update first

8. **Review Configuration**
   Your index configuration should look like this:
   ```
   Collection: parcels
   Fields indexed:
   - travelerId (Ascending)
   - lastStatusUpdate (Descending)
   Query scope: Collection
   ```

9. **Create the Index**
   - Click the "Create" button at the bottom
   - You'll be redirected to the Indexes page

10. **Wait for Index Build**
    - Status will show "Building" with a progress indicator
    - Build time depends on existing data:
      - Small databases (<1000 docs): 1-5 minutes
      - Medium databases (1000-10000 docs): 5-15 minutes
      - Large databases (>10000 docs): 15+ minutes
    - Refresh the page to check progress
    - When complete, status will change to "Enabled" with a green checkmark

### Verification

After the index is built:
- Status should show: "Enabled ✓"
- You'll see the index listed in the Composite indexes table
- The query will no longer fail with "index required" error

---

## Method 2: Create Index via Firebase CLI

### Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Authenticated: `firebase login`
- Firebase project initialized in your project directory

### Option A: Using Single Command

Run this command from your project root:

```bash
firebase firestore:indexes:create \
  --collection-group=parcels \
  --field=travelerId \
  --field-order=ASC \
  --field=lastStatusUpdate \
  --field-order=DESC
```

**Note:** The CLI command uses `--collection-group` flag, but since we're working with a collection (not a collection group), this will create a collection-scoped index.

### Option B: Using firestore.indexes.json File

1. **Create or Update firestore.indexes.json**

   Create/update the file at `/Users/macbook/Projects/parcel_am/firestore.indexes.json`:

   ```json
   {
     "indexes": [
       {
         "collectionGroup": "parcels",
         "queryScope": "COLLECTION",
         "fields": [
           {
             "fieldPath": "travelerId",
             "order": "ASCENDING"
           },
           {
             "fieldPath": "lastStatusUpdate",
             "order": "DESCENDING"
           }
         ]
       }
     ],
     "fieldOverrides": []
   }
   ```

2. **Deploy Indexes to Firestore**

   Run this command from your project root:

   ```bash
   firebase deploy --only firestore:indexes
   ```

3. **Monitor Deployment**

   The CLI will show progress:
   ```
   === Deploying to 'your-project-id'...

   i  firestore: reading indexes from firestore.indexes.json...
   ✔  firestore: deployed indexes in firestore.indexes.json successfully

   ✔  Deploy complete!
   ```

4. **Verify in Console**

   - Open Firebase Console > Firestore > Indexes
   - Check that the index appears and is building/enabled

### CLI Verification Command

Check index status using CLI:

```bash
firebase firestore:indexes
```

Output should include:
```
[ Collection parcels ]
Fields: travelerId Asc, lastStatusUpdate Desc
Status: Enabled
```

---

## Method 3: Automatic Index Creation (First Query)

### How It Works

When you first run a query that requires a composite index, Firestore will:
1. Detect that the index is missing
2. Return an error with a link to create the index
3. Provide a direct URL to auto-generate the index

### Triggering Auto-Creation

1. **Run the App**
   - Launch the app in development/staging environment
   - Navigate to the "My Deliveries" tab
   - The app will attempt to query parcels by travelerId and sort by lastStatusUpdate

2. **Observe the Error**
   - Check the console/logs for an error message:
   ```
   [cloud_firestore/failed-precondition] The query requires an index.
   You can create it here: https://console.firebase.google.com/...
   ```

3. **Click the Link**
   - Click the URL in the error message
   - You'll be taken to Firebase Console with pre-filled index configuration
   - Review the configuration (should match our requirements)
   - Click "Create Index"

4. **Wait for Build**
   - Index will start building automatically
   - Return to the app and wait for index completion
   - Retry the query after index is enabled

### Advantages
- No manual configuration needed
- Firestore automatically determines required fields
- Quickest method for development

### Disadvantages
- Requires triggering the error first
- Less control over index configuration
- Not suitable for production deployments (should create indexes proactively)

---

## Testing the Index

### Test 1: Verify Query Works

Run the following query in your Flutter app:

```dart
FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .orderBy('lastStatusUpdate', descending: true)
  .limit(20)
  .get();
```

**Expected Result:**
- Query completes successfully (< 1 second)
- No "index required" error
- Returns parcels sorted by most recent status update

### Test 2: Check Index Usage in Firebase Console

1. Navigate to Firebase Console > Firestore > Usage tab
2. Look for your query in the "Queries" section
3. Click on the query to see details
4. Verify that it shows "Index used: travelerId_lastStatusUpdate"

### Test 3: Performance Benchmark

Run this test query with timing:

```dart
final stopwatch = Stopwatch()..start();

final querySnapshot = await FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .orderBy('lastStatusUpdate', descending: true)
  .limit(50)
  .get();

stopwatch.stop();
print('Query time: ${stopwatch.elapsedMilliseconds}ms');
```

**Target Performance:**
- < 100ms for 1-100 documents
- < 200ms for 100-1000 documents
- < 500ms for 1000+ documents

### Test 4: Real-time Stream Updates

Test the real-time stream used in the app:

```dart
FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .orderBy('lastStatusUpdate', descending: true)
  .snapshots()
  .listen((snapshot) {
    print('Stream update: ${snapshot.docs.length} parcels');
  });
```

**Expected Result:**
- Initial snapshot loads quickly
- Updates arrive within 500ms when parcels change
- No errors in console

---

## Troubleshooting

### Issue 1: "Index Already Exists" Error

**Error Message:**
```
Index already exists with different configuration
```

**Solution:**
1. Go to Firebase Console > Firestore > Indexes
2. Find existing index on `parcels` collection
3. Check field configuration
4. If incorrect, delete the existing index
5. Wait for deletion to complete (1-2 minutes)
6. Create the correct index

### Issue 2: Index Build Stuck or Taking Too Long

**Symptoms:**
- Index shows "Building" for over 30 minutes
- No progress visible

**Solutions:**

**Option 1: Wait Longer**
- Large databases can take several hours
- Check Firebase Status page: https://status.firebase.google.com/

**Option 2: Check Firestore Quota**
- Navigate to Firebase Console > Firestore > Usage
- Verify you haven't exceeded daily index build quota
- Free tier: Limited index builds per day
- Blaze plan: Higher limits

**Option 3: Cancel and Recreate**
- Click on the building index
- Click "Delete" to cancel the build
- Wait 5 minutes
- Try creating the index again

### Issue 3: Query Still Fails After Index Created

**Error Message:**
```
The query requires an index...
```

**Possible Causes:**

1. **Index Not Fully Built**
   - Check Firebase Console - status must be "Enabled"
   - Wait for building to complete
   - Can take up to 1 hour for large datasets

2. **Wrong Field Order**
   - Verify field order matches: `travelerId` ASC, `lastStatusUpdate` DESC
   - Delete incorrect index
   - Create new index with correct configuration

3. **Wrong Query Scope**
   - Ensure index is "Collection" scope, not "Collection group"
   - Check query uses `.collection('parcels')` not `.collectionGroup('parcels')`

4. **Case Sensitivity**
   - Verify field names match exactly: `travelerId`, `lastStatusUpdate`
   - Firestore is case-sensitive

5. **Cache Issue**
   - Clear app data/cache
   - Restart the app
   - Try on a different device/emulator

### Issue 4: Missing Fields in Existing Documents

**Error:**
```
lastStatusUpdate is null for some documents
```

**This is expected behavior:**
- Old documents may not have `lastStatusUpdate` field
- The index will include documents with null values
- App should handle null values gracefully:

```dart
// Safe handling in code
parcel.lastStatusUpdate ?? DateTime.now()
```

**Optional Backfill:**
If you need all documents to have the field, run this migration:

```dart
Future<void> backfillLastStatusUpdate() async {
  final parcels = await FirebaseFirestore.instance
    .collection('parcels')
    .where('lastStatusUpdate', isNull: true)
    .get();

  final batch = FirebaseFirestore.instance.batch();

  for (final doc in parcels.docs) {
    final updatedAt = doc.data()['updatedAt'] as Timestamp?;
    if (updatedAt != null) {
      batch.update(doc.reference, {
        'lastStatusUpdate': updatedAt,
      });
    }
  }

  await batch.commit();
  print('Backfilled ${parcels.docs.length} documents');
}
```

### Issue 5: Security Rules Blocking Query

**Error:**
```
Missing or insufficient permissions
```

**Solution:**
Update Firestore Security Rules to allow travelers to query their parcels:

```javascript
match /parcels/{parcelId} {
  // Allow travelers to read their assigned parcels
  allow read: if request.auth != null &&
                 request.auth.uid == resource.data.travelerId;

  // Allow travelers to update status
  allow update: if request.auth != null &&
                   request.auth.uid == resource.data.travelerId &&
                   request.resource.data.diff(resource.data).affectedKeys()
                     .hasOnly(['status', 'lastStatusUpdate', 'courierNotes', 'metadata']);
}
```

---

## Additional Indexes (Optional)

### Index 2: Traveler Deliveries by Status

If you implement status filtering (Active vs Completed), you may need an additional index:

**Configuration:**
- Collection: `parcels`
- Fields:
  1. `travelerId` (Ascending)
  2. `status` (Ascending)
  3. `lastStatusUpdate` (Descending)

**Firebase Console Steps:**
Same as above, but add three fields instead of two.

**CLI Command:**
```bash
firebase firestore:indexes:create \
  --collection-group=parcels \
  --field=travelerId \
  --field-order=ASC \
  --field=status \
  --field-order=ASC \
  --field=lastStatusUpdate \
  --field-order=DESC
```

**When Required:**
This index is needed for queries like:

```dart
FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .where('status', isEqualTo: 'in_transit')
  .orderBy('lastStatusUpdate', descending: true)
  .get();
```

**Note:** Only create this index if you're using status-based filtering in the UI. Otherwise, the primary index is sufficient.

---

## Monitoring and Maintenance

### Regular Monitoring Tasks

**Weekly:**
1. Check Firebase Console > Firestore > Usage
2. Review query performance metrics
3. Look for slow queries (> 1 second)
4. Check index usage statistics

**Monthly:**
1. Review all indexes in Firebase Console
2. Delete unused indexes to reduce costs
3. Analyze query patterns for optimization
4. Check for new index recommendations

### Index Cost Considerations

**Storage Cost:**
- Each index adds storage overhead
- Index size = number of documents × fields indexed
- For 10,000 parcels: ~1-2 MB per index

**Write Cost:**
- Each document write updates all indexes
- More indexes = higher write costs
- Status updates will update the `lastStatusUpdate` field

**Read Cost:**
- Index reads are counted in query costs
- Properly indexed queries are cheaper than full collection scans

### Best Practices

1. **Only Create Needed Indexes**
   - Each index has a cost
   - Only add indexes for queries you actually run
   - Review and remove unused indexes

2. **Test Before Deploying**
   - Create indexes in development/staging first
   - Test query performance
   - Verify correctness before production

3. **Monitor Index Usage**
   - Use Firebase Console to track index usage
   - Remove indexes with zero usage
   - Optimize based on actual query patterns

4. **Consider Index Exemptions**
   - For rarely-used queries, you may skip indexing
   - Use single-field indexes instead of composite when possible
   - Balance performance vs cost

5. **Plan for Scale**
   - Test with realistic data volumes
   - Index build times increase with data size
   - Plan maintenance windows for index updates

---

## Summary

This guide covered three methods for creating the required Firestore composite index:

1. **Firebase Console (UI):** Best for manual, one-time setup
2. **Firebase CLI:** Best for automated deployments and version control
3. **Automatic Creation:** Best for quick development, not recommended for production

**Recommended Approach:**
- **Development:** Use automatic creation (Method 3) for rapid iteration
- **Staging/Production:** Use Firebase CLI (Method 2) with `firestore.indexes.json` for version-controlled, reproducible deployments

**Key Takeaways:**
- The index enables efficient querying of traveler's parcels sorted by recent activity
- Index build time varies based on existing data volume
- Always verify index is "Enabled" before deploying to production
- Monitor index usage and performance regularly
- Handle null `lastStatusUpdate` values gracefully in code

**Next Steps:**
1. Create the index using your preferred method
2. Wait for index build completion
3. Run the test queries to verify functionality
4. Monitor performance in Firebase Console
5. Deploy your app with confidence that queries will perform efficiently

For questions or issues, refer to:
- Firebase Documentation: https://firebase.google.com/docs/firestore/query-data/indexing
- Firebase Support: https://firebase.google.com/support
- Project spec: `/Users/macbook/Projects/parcel_am/agent-os/specs/2025-11-25-accepted-requests-delivery-tracking/firestore-schema.md`
