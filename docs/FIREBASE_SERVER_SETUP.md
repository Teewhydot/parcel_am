# Firebase Server Setup Guide for TravelLink

This guide will walk you through setting up Firebase Authentication on the server side for your Nigerian parcel delivery app.

## 🔥 Firebase Console Setup

### Step 1: Create Firebase Project

1. **Go to Firebase Console**
   - Visit [https://console.firebase.google.com](https://console.firebase.google.com)
   - Sign in with your Google account

2. **Create New Project**
   - Click "Add project" or "Create a project"
   - Project name: `travellink-parcel-delivery`
   - Project ID: `travellink-parcel-delivery` (or similar, must be unique)
   - Enable Google Analytics: **Yes** (recommended for tracking)
   - Choose Analytics account: Use default or create new

3. **Wait for Project Creation**
   - Firebase will set up your project (takes 1-2 minutes)

### Step 2: Add Android App

1. **Register Android App**
   - Click "Add app" → Android icon
   - Android package name: `com.example.parcel_am` (from your `android/app/build.gradle`)
   - App nickname: `TravelLink Android`
   - Debug signing certificate SHA-1: **Required for Phone Auth**

2. **Generate SHA-1 Certificate**
   
   **Method 1: Using Gradle (Recommended)**
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Look for SHA1 under `Variant: debug` → `Config: debug`

   **Method 2: Using Keytool (Windows)**
   ```cmd
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

   **Method 3: Using Keytool (Linux/Mac)**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

3. **Download google-services.json**
   - Download the configuration file
   - Place it in `android/app/google-services.json`
   - **Important**: This file is already configured in your project

### Step 3: Configure Authentication

1. **Enable Authentication**
   - Go to "Authentication" in Firebase Console
   - Click "Get started"

2. **Configure Phone Authentication**
   - Go to "Sign-in method" tab
   - Find "Phone" provider
   - Click "Phone" → "Enable"
   - **Important Settings**:
     - Enable Phone sign-in: **✅ ON**
     - Phone numbers for testing: Add your test numbers
     - reCAPTCHA verification: **Enabled** (required for web)

3. **Add Test Phone Numbers (For Development)**
   ```
   Phone Number: +234 801 234 5678
   SMS Code: 123456
   
   Phone Number: +234 802 345 6789  
   SMS Code: 654321
   ```
   
   **Why Test Numbers?**
   - Avoid SMS costs during development
   - Consistent testing experience
   - No rate limiting issues

### Step 4: Configure App Check (Security)

1. **Enable App Check**
   - Go to "App Check" in Firebase Console
   - Click "Get started"

2. **Register Your App**
   - Select your Android app
   - Provider: **Play Integrity API** (for production)
   - For development: **Debug provider**

3. **Enforcement**
   - Enable enforcement for "Authentication"
   - This prevents unauthorized access to your Firebase project

### Step 5: SMS Configuration

1. **SMS Provider Setup**
   - Firebase uses multiple SMS providers automatically
   - Default quota: 10 SMS/day for Spark plan
   - For production: Upgrade to Blaze plan

2. **Quota Management**
   - Spark (Free): 10 SMS verifications/day
   - Blaze (Pay-as-you-go): $0.01 per SMS (Nigeria)
   - Set up billing alerts to monitor usage

### Step 6: Regional Settings

1. **Configure for Nigeria**
   - Go to Project Settings → General
   - Default GCP resource location: **us-central1** (recommended)
   - Time zone: **(GMT+01:00) Lagos**

2. **Phone Number Validation**
   - Your app is already configured for Nigerian numbers
   - Supported formats: +234XXXXXXXXXX
   - Local format handling: 0XXXXXXXXXX → +234XXXXXXXXXX

## 🔧 Advanced Configuration

### Security Rules

1. **Firestore Rules** (if you add Firestore later)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can only access their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       
       // Parcels - users can read/write their own
       match /parcels/{parcelId} {
         allow read, write: if request.auth != null && 
           (resource.data.senderId == request.auth.uid || 
            resource.data.travelerId == request.auth.uid);
       }
     }
   }
   ```

2. **Storage Rules** (for document uploads)
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /user-documents/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Production Considerations

1. **Rate Limiting**
   - Implement client-side delays between OTP requests
   - Your app already has 60-second cooldown
   - Consider server-side rate limiting for additional security

2. **Monitoring**
   - Set up Firebase Analytics
   - Enable Crashlytics for error tracking
   - Monitor authentication success/failure rates

3. **Backup & Recovery**
   - Export user data regularly
   - Set up Firebase project backup
   - Document your configuration changes

## 📱 Testing Your Setup

### 1. Test with Debug Build

```bash
# Build debug APK
flutter build apk --debug

# Install on device
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Test Phone Authentication Flow

1. **Use Test Phone Numbers** (in development)
   - Enter: +234 801 234 5678
   - Expected SMS code: 123456
   - Should authenticate successfully

2. **Test Real Numbers** (carefully)
   - Use your actual Nigerian phone number
   - Verify SMS is received
   - Check Firebase Console → Authentication → Users

### 3. Verify Authentication Events

In Firebase Console → Authentication → Users:
- New users should appear after successful authentication
- Check user UID matches your app logs
- Verify phone number is stored correctly

## 🚨 Troubleshooting

### Common Issues

1. **"Network Error" during OTP**
   - Check SHA-1 certificate is correct
   - Verify google-services.json is in correct location
   - Ensure device has internet connection

2. **"Invalid Phone Number"**
   - Verify Nigerian format: +234XXXXXXXXXX
   - Check FirebaseConfig.validPrefixes includes your number prefix
   - Test with known working prefixes: 803, 806, 813, 816

3. **"Quota Exceeded"**
   - Upgrade to Blaze plan
   - Use test phone numbers during development
   - Implement request throttling

4. **"App Check Token Invalid"**
   - Disable App Check enforcement during development
   - Register debug certificates properly
   - For production: Use Play Integrity API

### Debug Commands

```bash
# Check Firebase connection
flutter packages pub run firebase_auth:firebase_auth_debug

# View detailed logs
flutter logs --verbose

# Check SHA-1 in APK
unzip -q -c app-debug.apk META-INF/MANIFEST.MF | grep -E "SHA1-Digest"
```

## 📊 Monitoring & Analytics

### Firebase Analytics Events

Your app automatically tracks:
- `sign_up`: New user registration
- `login`: Successful authentication
- `phone_verification_started`: OTP request
- `phone_verification_completed`: OTP success

### Custom Events to Add

```dart
// Track authentication attempts
FirebaseAnalytics.instance.logEvent(
  name: 'auth_attempt',
  parameters: {
    'method': 'phone',
    'country_code': 'NG',
  },
);

// Track successful parcel creation
FirebaseAnalytics.instance.logEvent(
  name: 'parcel_created',
  parameters: {
    'user_type': 'sender',
    'delivery_type': 'express',
  },
);
```

## 🚀 Production Deployment

### Before Going Live

1. **✅ Security Checklist**
   - [ ] App Check enabled and enforcing
   - [ ] Production SHA-1 certificates added
   - [ ] Test phone numbers removed
   - [ ] Rate limiting implemented
   - [ ] Analytics configured

2. **✅ Performance Checklist**
   - [ ] Blaze plan activated (for SMS quota)
   - [ ] Monitoring alerts set up
   - [ ] Error tracking enabled
   - [ ] User feedback system ready

3. **✅ Compliance Checklist**
   - [ ] Privacy policy updated
   - [ ] Terms of service include authentication
   - [ ] GDPR compliance (if applicable)
   - [ ] Nigerian data protection compliance

### Launch Configuration

```yaml
# Production firebase configuration
firebase:
  app_check:
    enforcement: true
  auth:
    phone:
      test_numbers: [] # Remove all test numbers
      rate_limiting: true
  analytics:
    enabled: true
  crashlytics:
    enabled: true
```

## 📞 Support & Resources

- **Firebase Documentation**: [https://firebase.google.com/docs/auth/android/phone-auth](https://firebase.google.com/docs/auth/android/phone-auth)
- **Flutter Firebase**: [https://firebase.flutter.dev/docs/auth/phone](https://firebase.flutter.dev/docs/auth/phone)
- **Nigerian Phone Formats**: [https://en.wikipedia.org/wiki/Telephone_numbers_in_Nigeria](https://en.wikipedia.org/wiki/Telephone_numbers_in_Nigeria)
- **Firebase Support**: [https://support.google.com/firebase](https://support.google.com/firebase)

---

**🎉 Your Firebase server setup is now complete!** 

The TravelLink authentication system is ready for Nigerian users with secure phone number verification. Remember to test thoroughly before production deployment.