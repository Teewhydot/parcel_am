# Users Collection - FCM Tokens Update

## Overview
Update the `users` collection to support storing multiple FCM device tokens for each user, enabling multi-device push notifications.

## Updated Schema

### Collection Path
`users/{userId}`

### New Field

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| fcmTokens | array | No | Array of FCM device tokens for this user's devices |

### Example Document

```json
{
  "id": "user123",
  "email": "john.doe@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://example.com/photo.jpg",
  "fcmTokens": [
    "eXaMpLeToKeN1234567890aBcDeF...",
    "aNothErToKeN0987654321FeDcBa..."
  ],
  "createdAt": "2025-11-01T10:00:00.000Z",
  "updatedAt": "2025-11-14T10:30:00.000Z"
}
```

## Index Configuration

### Array-Contains Index on fcmTokens
**Required for:** Finding users by FCM token for targeted notifications

**To create in Firebase Console:**
1. Go to Firestore Database > Indexes
2. Click "Create Index"
3. Select collection: `users`
4. Add field: `fcmTokens` with collection group scope
5. Set query scope: Collection
6. Click "Create"

## Implementation Notes

### Adding FCM Token
When a user logs in on a new device:

```dart
Future<void> addFcmToken(String userId, String token) async {
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });
}
```

### Removing FCM Token
When a user logs out from a device:

```dart
Future<void> removeFcmToken(String userId, String token) async {
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
      'fcmTokens': FieldValue.arrayRemove([token])
    });
}
```

### Token Refresh
When FCM token is refreshed:

```dart
Future<void> updateFcmToken(String userId, String oldToken, String newToken) async {
  final batch = FirebaseFirestore.instance.batch();
  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

  // Remove old token and add new token
  batch.update(userRef, {
    'fcmTokens': FieldValue.arrayRemove([oldToken])
  });
  batch.update(userRef, {
    'fcmTokens': FieldValue.arrayUnion([newToken])
  });

  await batch.commit();
}
```

### Getting User's FCM Tokens
For sending notifications to all user's devices:

```dart
Future<List<String>> getUserFcmTokens(String userId) async {
  final doc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

  if (doc.exists && doc.data()?['fcmTokens'] != null) {
    return List<String>.from(doc.data()!['fcmTokens']);
  }
  return [];
}
```

## Security Rules

The updated security rules in `firestore.rules` allow users to update their own FCM tokens:

```
match /users/{userId} {
  // Allow updating FCM tokens
  allow update: if isOwner(userId)
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmTokens']);
}
```

## Migration Guide

### For Existing Users
If you have existing users without the `fcmTokens` field:

**Option 1: Lazy Migration**
- The field will be added automatically when users log in and their FCM token is registered
- No manual migration needed

**Option 2: Batch Migration**
Initialize empty arrays for all existing users:

```dart
Future<void> migrateExistingUsers() async {
  final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('fcmTokens', isNull: true)
    .get();

  final batch = FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    batch.update(doc.reference, {'fcmTokens': []});
  }
  await batch.commit();
}
```

## Cloud Functions Integration

### Sending Notifications to All User Devices

```javascript
const admin = require('firebase-admin');

async function sendNotificationToUser(userId, notification) {
  // Get user's FCM tokens
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .get();

  const fcmTokens = userDoc.data()?.fcmTokens || [];

  if (fcmTokens.length === 0) {
    console.log('No FCM tokens found for user:', userId);
    return;
  }

  // Send to all devices
  const message = {
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: notification.data,
    tokens: fcmTokens,
  };

  const response = await admin.messaging().sendMulticast(message);

  // Remove invalid tokens
  const invalidTokens = [];
  response.responses.forEach((resp, idx) => {
    if (!resp.success) {
      invalidTokens.push(fcmTokens[idx]);
    }
  });

  if (invalidTokens.length > 0) {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens)
      });
  }

  return response;
}
```

## Best Practices

1. **Token Deduplication**: The `arrayUnion` operation automatically prevents duplicate tokens
2. **Token Cleanup**: Remove invalid tokens when FCM send fails
3. **Token Limit**: Consider limiting the number of tokens per user (e.g., 10 devices max)
4. **Token Expiry**: FCM tokens can expire, so handle token refresh properly
5. **Privacy**: Never expose user tokens in client-side queries or APIs
