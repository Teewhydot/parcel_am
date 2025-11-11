# Firestore Security Rules for Wallet Collection

Add these security rules to your Firebase Console under Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Wallet collection rules
    match /wallets/{userId} {
      // Users can only read their own wallet
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can create their own wallet (on first login/registration)
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Only allow updates from authenticated backend or admin
      // In production, remove write access and use Cloud Functions
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Prevent deletion
      allow delete: if false;
    }
  }
}
```

## Production Recommendation

For production apps, wallet balance updates should be done via Cloud Functions with admin privileges to prevent client-side manipulation. The security rules should only allow read access:

```javascript
match /wallets/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow create: if false; // Use Cloud Function
  allow update: if false; // Use Cloud Function
  allow delete: if false;
}
```

Then use Firebase Admin SDK in Cloud Functions to safely update wallet balances.
