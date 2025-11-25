# Firestore Schema Documentation: Delivery Tracking

## Overview
This document defines the Firestore schema updates required for the Accepted Requests Delivery Tracking feature. The schema has been designed to support delivery status progression, real-time tracking, and backward compatibility with existing parcel documents.

## Collection: `parcels`

### Document Structure

#### New Fields

##### `lastStatusUpdate` (Timestamp, optional)
- **Type:** Firestore Timestamp
- **Description:** Timestamp of the most recent status update for the parcel
- **Purpose:** Used for sorting deliveries by recent activity and efficient querying
- **Default:** `null` (for existing documents)
- **Updated:** Automatically set whenever the status field is updated

##### `courierNotes` (String, optional)
- **Type:** String
- **Description:** Optional notes from the courier about the delivery
- **Purpose:** Allows couriers to add pickup/delivery instructions, issues encountered, or other relevant notes
- **Default:** `null`
- **Example:** "Left package with neighbor in apartment 2B", "Recipient not home, will redeliver tomorrow"

##### `metadata` (Map, optional)
- **Type:** Map<String, dynamic>
- **Description:** Flexible metadata field for delivery tracking and future extensions
- **Default:** `null`
- **Structure:**
  ```dart
  {
    "deliveryStatusHistory": {
      "paid": "2025-11-25T10:30:00.000Z",
      "picked_up": "2025-11-25T12:00:00.000Z",
      "in_transit": "2025-11-25T14:30:00.000Z",
      "arrived": "2025-11-26T08:00:00.000Z",
      "delivered": "2025-11-26T10:15:00.000Z"
    }
  }
  ```

#### Metadata Field Structure

##### `metadata.deliveryStatusHistory` (Map, optional)
- **Type:** Map<String, String>
- **Key:** Status name in snake_case format (e.g., "paid", "picked_up", "in_transit", "arrived", "delivered")
- **Value:** ISO 8601 timestamp string (e.g., "2025-11-25T10:30:00.000Z")
- **Purpose:** Tracks the complete timeline of status changes for audit and display purposes
- **Updated:** A new entry is added each time the status progresses

### Example Document: Before (Existing Structure)

```json
{
  "id": "parcel_123",
  "sender": {
    "userId": "user_abc",
    "name": "John Doe",
    "phoneNumber": "+1234567890",
    "address": "123 Main St, New York, NY",
    "email": "john@example.com"
  },
  "receiver": {
    "name": "Jane Smith",
    "phoneNumber": "+0987654321",
    "address": "456 Oak Ave, Los Angeles, CA",
    "email": "jane@example.com"
  },
  "route": {
    "origin": "New York, NY",
    "destination": "Los Angeles, CA",
    "originLat": 40.7128,
    "originLng": -74.0060,
    "destinationLat": 34.0522,
    "destinationLng": -118.2437,
    "estimatedDeliveryDate": "2025-11-28T18:00:00.000Z",
    "actualDeliveryDate": null
  },
  "status": "paid",
  "travelerId": "courier_xyz",
  "travelerName": "Mike Johnson",
  "weight": 2.5,
  "dimensions": "30x20x15 cm",
  "category": "Electronics",
  "description": "Laptop computer",
  "price": 50.00,
  "currency": "USD",
  "imageUrl": "https://example.com/image.jpg",
  "escrowId": "escrow_789",
  "createdAt": Timestamp(2025-11-25 09:00:00),
  "updatedAt": Timestamp(2025-11-25 10:30:00)
}
```

### Example Document: After (With Delivery Tracking)

```json
{
  "id": "parcel_123",
  "sender": {
    "userId": "user_abc",
    "name": "John Doe",
    "phoneNumber": "+1234567890",
    "address": "123 Main St, New York, NY",
    "email": "john@example.com"
  },
  "receiver": {
    "name": "Jane Smith",
    "phoneNumber": "+0987654321",
    "address": "456 Oak Ave, Los Angeles, CA",
    "email": "jane@example.com"
  },
  "route": {
    "origin": "New York, NY",
    "destination": "Los Angeles, CA",
    "originLat": 40.7128,
    "originLng": -74.0060,
    "destinationLat": 34.0522,
    "destinationLng": -118.2437,
    "estimatedDeliveryDate": "2025-11-28T18:00:00.000Z",
    "actualDeliveryDate": null
  },
  "status": "in_transit",
  "travelerId": "courier_xyz",
  "travelerName": "Mike Johnson",
  "weight": 2.5,
  "dimensions": "30x20x15 cm",
  "category": "Electronics",
  "description": "Laptop computer",
  "price": 50.00,
  "currency": "USD",
  "imageUrl": "https://example.com/image.jpg",
  "escrowId": "escrow_789",
  "createdAt": Timestamp(2025-11-25 09:00:00),
  "updatedAt": Timestamp(2025-11-25 14:30:00),
  "lastStatusUpdate": Timestamp(2025-11-25 14:30:00),
  "courierNotes": "Package picked up successfully. En route to Los Angeles.",
  "metadata": {
    "deliveryStatusHistory": {
      "paid": "2025-11-25T10:30:00.000Z",
      "picked_up": "2025-11-25T12:00:00.000Z",
      "in_transit": "2025-11-25T14:30:00.000Z"
    }
  }
}
```

## Composite Indexes

### Required Index 1: Traveler Deliveries by Recent Activity

**Purpose:** Efficiently query parcels assigned to a specific courier, sorted by most recent status updates

**Index Configuration:**
- **Collection:** `parcels`
- **Fields:**
  1. `travelerId` (Ascending)
  2. `lastStatusUpdate` (Descending)
- **Query Scope:** Collection
- **Use Case:** Powers the "My Deliveries" tab, showing courier's active and completed deliveries

**Firebase CLI Command:**
```bash
firebase firestore:indexes:create \
  --collection-group=parcels \
  --field=travelerId \
  --field-order=ASC \
  --field=lastStatusUpdate \
  --field-order=DESC
```

**Manual Creation (Firebase Console):**
1. Navigate to Firebase Console > Firestore Database > Indexes
2. Click "Create Index"
3. Collection ID: `parcels`
4. Fields to index:
   - Field: `travelerId`, Order: Ascending
   - Field: `lastStatusUpdate`, Order: Descending
5. Query scope: Collection
6. Click "Create"

**Expected Query Performance:**
- With index: < 100ms for 1000+ documents
- Without index: Query will fail or timeout

### Required Index 2: Traveler Deliveries by Status

**Purpose:** Filter and query parcels by traveler and status (e.g., active vs. completed deliveries)

**Index Configuration:**
- **Collection:** `parcels`
- **Fields:**
  1. `travelerId` (Ascending)
  2. `status` (Ascending)
- **Query Scope:** Collection
- **Use Case:** Filtering deliveries in "My Deliveries" tab by Active/Completed status

**Firebase CLI Command:**
```bash
firebase firestore:indexes:create \
  --collection-group=parcels \
  --field=travelerId \
  --field-order=ASC \
  --field=status \
  --field-order=ASC
```

**Manual Creation (Firebase Console):**
1. Navigate to Firebase Console > Firestore Database > Indexes
2. Click "Create Index"
3. Collection ID: `parcels`
4. Fields to index:
   - Field: `travelerId`, Order: Ascending
   - Field: `status`, Order: Ascending
5. Query scope: Collection
6. Click "Create"

## Example Queries

### Query 1: Get All Accepted Parcels for a Courier (Sorted by Recent Activity)

**Purpose:** Retrieve all parcels where the current user is the traveler, sorted by most recent status updates

**Firestore Query:**
```dart
FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .orderBy('lastStatusUpdate', descending: true)
  .snapshots();
```

**Returns:** Stream of parcel documents ordered by most recently updated first

**Required Index:** Traveler Deliveries by Recent Activity (`travelerId` ASC, `lastStatusUpdate` DESC)

### Query 2: Get Active Deliveries for a Courier

**Purpose:** Retrieve only active deliveries (status: paid, picked_up, in_transit, arrived)

**Firestore Query:**
```dart
FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .where('status', whereIn: ['paid', 'picked_up', 'in_transit', 'arrived'])
  .orderBy('lastStatusUpdate', descending: true)
  .snapshots();
```

**Returns:** Stream of active parcel documents

**Required Index:** Composite index on (`travelerId`, `status`, `lastStatusUpdate`)

**Note:** This query may require an additional composite index that Firestore will suggest when first executed.

### Query 3: Get Completed Deliveries for a Courier

**Purpose:** Retrieve only completed deliveries (status: delivered)

**Firestore Query:**
```dart
FirebaseFirestore.instance
  .collection('parcels')
  .where('travelerId', isEqualTo: currentUserId)
  .where('status', isEqualTo: 'delivered')
  .orderBy('lastStatusUpdate', descending: true)
  .snapshots();
```

**Returns:** Stream of completed parcel documents

**Required Index:** Traveler Deliveries by Status (`travelerId` ASC, `status` ASC) + `lastStatusUpdate` DESC

### Query 4: Get Parcels with Status History

**Purpose:** Retrieve parcel and parse its delivery status history

**Code Example:**
```dart
// Get parcel document
final doc = await FirebaseFirestore.instance
  .collection('parcels')
  .doc(parcelId)
  .get();

// Parse metadata
final data = doc.data() as Map<String, dynamic>;
final metadata = data['metadata'] as Map<String, dynamic>?;
final historyMap = metadata?['deliveryStatusHistory'] as Map<String, dynamic>?;

// Convert to DateTime map
final history = <String, DateTime>{};
historyMap?.forEach((key, value) {
  if (value is String) {
    try {
      history[key] = DateTime.parse(value);
    } catch (e) {
      // Skip invalid timestamps
    }
  }
});

// Access specific status timestamp
final pickedUpTime = history['picked_up'];
print('Picked up at: $pickedUpTime');
```

## Migration Strategy

### No Database Migration Required

The new fields (`lastStatusUpdate`, `courierNotes`, `metadata`) are **optional** and nullable, ensuring complete backward compatibility:

1. **Existing Documents:**
   - Will continue to work without any changes
   - Missing fields will be treated as `null`
   - No data loss or corruption risk

2. **New Documents:**
   - Will include new fields when created
   - `lastStatusUpdate` set when status is updated
   - `metadata.deliveryStatusHistory` populated on status changes

3. **Mixed Environment:**
   - App handles both old and new document structures seamlessly
   - Graceful degradation for missing fields

### Gradual Field Population

Fields will be populated naturally as parcels are updated:

1. **Immediate (No Action Required):**
   - Existing parcels without new fields work as-is
   - Code checks for null values before accessing fields

2. **On First Status Update:**
   - `lastStatusUpdate` field is set
   - `metadata.deliveryStatusHistory` initialized with current status

3. **Progressive Enhancement:**
   - As couriers update statuses, history is built
   - Over time, all active parcels gain full tracking data

### Optional: Backfill Script

If historical data is needed for existing parcels, run this optional migration:

```dart
// OPTIONAL: Backfill lastStatusUpdate for existing parcels
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
}
```

**Note:** This backfill is **NOT required** for the feature to work. Only run if historical sorting accuracy is critical.

## Status Progression Rules

### Valid Status Flow

```
created -> paid -> picked_up -> in_transit -> arrived -> delivered
```

### Terminal Statuses
- `delivered` - Final successful state
- `cancelled` - Cancelled by user
- `disputed` - Under dispute resolution

### Business Rules

1. **No Backward Progression:**
   - Once a status is advanced, it cannot regress
   - Example: Cannot go from `in_transit` back to `picked_up`

2. **Sequential Advancement:**
   - Must follow the defined flow order
   - Cannot skip statuses (e.g., cannot go from `paid` to `arrived` without intermediate steps)

3. **Timestamp Validation:**
   - Each status change timestamp must be after the previous status
   - `lastStatusUpdate` should always match the most recent status timestamp

4. **Client-Side Validation:**
   - UI prevents invalid status transitions
   - Only shows next valid status in progression

5. **Server-Side Validation (Recommended):**
   - Firestore Security Rules should validate status progression
   - Prevent unauthorized status updates

### Example Security Rule

```javascript
// Firestore Security Rules for status validation
match /parcels/{parcelId} {
  // Helper function to validate status progression
  function isValidStatusProgression(oldStatus, newStatus) {
    return (oldStatus == 'paid' && newStatus == 'picked_up') ||
           (oldStatus == 'picked_up' && newStatus == 'in_transit') ||
           (oldStatus == 'in_transit' && newStatus == 'arrived') ||
           (oldStatus == 'arrived' && newStatus == 'delivered');
  }

  // Allow courier to update status
  allow update: if request.auth != null &&
                   request.auth.uid == resource.data.travelerId &&
                   isValidStatusProgression(resource.data.status,
                                           request.resource.data.status);
}
```

## Performance Considerations

### Index Creation Time
- Small databases (<1000 documents): 1-5 minutes
- Medium databases (1000-10000 documents): 5-15 minutes
- Large databases (>10000 documents): 15+ minutes

### Query Performance Targets
- List accepted parcels: < 100ms
- Update parcel status: < 200ms
- Real-time stream updates: < 500ms latency

### Optimization Tips

1. **Use Pagination:**
   - Limit query results to 20-50 parcels per page
   - Use `startAfter()` for pagination
   - Prevents large document transfers

2. **Selective Field Retrieval:**
   - Use `.select()` to retrieve only needed fields
   - Reduces bandwidth and deserialization time

3. **Offline Persistence:**
   - Enable Firestore offline persistence
   - Provides instant UI updates
   - Syncs when online

4. **Optimize Listeners:**
   - Unsubscribe from streams when not needed
   - Avoid duplicate listeners on same query

## Troubleshooting

### Index Not Found Error

**Error Message:**
```
The query requires an index. You can create it here: [URL]
```

**Solution:**
1. Click the provided URL to auto-create the index
2. Wait for index build completion (check Firebase Console)
3. Retry the query

**Alternative:**
Use Firebase CLI commands provided above to create indexes manually

### Missing Field Errors

**Error:** `lastStatusUpdate` or `metadata` is null

**Solution:**
- Check for null before accessing: `parcel.lastStatusUpdate ?? DateTime.now()`
- Use null-safe operators: `parcel.metadata?['deliveryStatusHistory']`
- The app is designed to handle missing fields gracefully

### Status Update Failures

**Symptom:** Status update doesn't persist or gets rejected

**Possible Causes:**
1. Security rules blocking update
2. Invalid status progression
3. Network connectivity issues
4. Firestore quota exceeded

**Debugging:**
1. Check Firebase Console > Firestore > Rules
2. Review client-side validation logic
3. Check network logs
4. Verify Firestore usage limits

## Monitoring and Maintenance

### Recommended Monitoring

1. **Query Performance:**
   - Monitor query execution times in Firebase Console
   - Set alerts for slow queries (>1 second)

2. **Index Usage:**
   - Review index usage statistics
   - Remove unused indexes to reduce costs

3. **Document Size:**
   - Monitor average document size
   - `metadata` field should remain small (<1KB)
   - Consider archiving old status history if needed

4. **Write Operations:**
   - Track number of status updates
   - Monitor for unusual patterns
   - Set budget alerts for write costs

### Regular Maintenance Tasks

1. **Monthly:**
   - Review index performance
   - Check for slow queries
   - Validate security rules

2. **Quarterly:**
   - Archive completed deliveries (>90 days old)
   - Analyze query patterns
   - Optimize indexes based on usage

3. **Annually:**
   - Review schema for new features
   - Consider data retention policies
   - Audit security rules

## Summary

This schema update enables robust delivery tracking with:

- **Real-time status updates** via Firestore streams
- **Complete status history** in metadata field
- **Efficient querying** with composite indexes
- **Backward compatibility** through optional fields
- **Scalable architecture** for future enhancements

All new fields are optional, ensuring existing parcels continue to work without modification while new parcels benefit from enhanced tracking capabilities.
