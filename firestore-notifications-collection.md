# Firestore Notifications Collection Structure

## Collection Path
`notifications`

## Document Structure

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| userId | string | Yes | ID of the user who owns this notification |
| type | string | Yes | Type of notification: 'chat_message', 'system_alert', 'announcement', 'reminder' |
| title | string | Yes | Notification title |
| body | string | Yes | Notification body/message |
| data | map | Yes | Additional data payload (can be empty map) |
| timestamp | timestamp | Yes | When the notification was created |
| isRead | boolean | Yes | Whether the notification has been read |
| chatId | string | No | Chat ID if notification is related to a chat |
| senderId | string | No | User ID of the sender if notification is from another user |
| senderName | string | No | Name of the sender for display purposes |

### Example Document

```json
{
  "userId": "user123",
  "type": "chat_message",
  "title": "New Message",
  "body": "John Doe sent you a message",
  "data": {
    "chatId": "chat456",
    "messagePreview": "Hello there!"
  },
  "timestamp": "2025-11-14T10:30:00.000Z",
  "isRead": false,
  "chatId": "chat456",
  "senderId": "user789",
  "senderName": "John Doe"
}
```

## Indexes

### Compound Index 1: User Notifications Query
**Required for:** Querying user's notifications ordered by timestamp

- Collection: `notifications`
- Fields indexed:
  - `userId` (Ascending)
  - `timestamp` (Descending)

**To create in Firebase Console:**
1. Go to Firestore Database > Indexes
2. Click "Create Index"
3. Select collection: `notifications`
4. Add field: `userId` with order `Ascending`
5. Add field: `timestamp` with order `Descending`
6. Query scope: Collection
7. Click "Create"

### Index 2: FCM Tokens (in users collection)
**Required for:** Efficiently finding users by FCM token

- Collection: `users`
- Field: `fcmTokens` (Array)

**To create in Firebase Console:**
1. Go to Firestore Database > Indexes
2. Click "Create Index"
3. Select collection: `users`
4. Add field: `fcmTokens` with array-contains
5. Click "Create"

## TTL Policy for Automatic Cleanup

**Goal:** Automatically delete notifications older than 30 days

**Implementation Options:**

### Option 1: Firebase Extensions (Recommended)
Use the "Delete Collections" Firebase Extension:
1. Install the extension from Firebase Console > Extensions
2. Configure to run daily
3. Set collection path: `notifications`
4. Set filter: `timestamp < (current_time - 30 days)`

### Option 2: Cloud Functions (Manual Implementation)
Create a scheduled Cloud Function that runs daily:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('timestamp', '<', thirtyDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.size} old notifications`);
  });
```

### Option 3: Client-Side Cleanup
Implement periodic cleanup in the app when user accesses notifications:

```dart
Future<void> cleanupOldNotifications() async {
  final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

  final snapshot = await FirebaseFirestore.instance
    .collection('notifications')
    .where('userId', isEqualTo: currentUserId)
    .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
    .get();

  final batch = FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();
}
```

## Query Examples

### Get User's Notifications (Paginated)
```dart
FirebaseFirestore.instance
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .orderBy('timestamp', descending: true)
  .limit(20)
  .snapshots();
```

### Get Unread Notifications Count
```dart
FirebaseFirestore.instance
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .where('isRead', isEqualTo: false)
  .snapshots();
```

### Mark Notification as Read
```dart
FirebaseFirestore.instance
  .collection('notifications')
  .doc(notificationId)
  .update({'isRead': true});
```

### Mark All as Read
```dart
final snapshot = await FirebaseFirestore.instance
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .where('isRead', isEqualTo: false)
  .get();

final batch = FirebaseFirestore.instance.batch();
for (var doc in snapshot.docs) {
  batch.update(doc.reference, {'isRead': true});
}
await batch.commit();
```
