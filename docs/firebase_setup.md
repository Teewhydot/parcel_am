# Firebase Setup Guide for TravelLink

## Prerequisites
- Firebase account (create at https://firebase.google.com)
- Android Studio installed (for SHA certificates)
- Flutter project (already configured)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create Project"
3. Name it: `travellink-parcel` (or similar)
4. Disable Google Analytics (optional, can enable later)
5. Click "Create Project"

## Step 2: Enable Phone Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Phone**
3. Enable the Phone provider
4. Add test phone numbers for development:
   ```
   +234 123 456 7890 → OTP: 123456
   +234 123 456 7891 → OTP: 123456
   +234 123 456 7892 → OTP: 123456
   +234 123 456 7893 → OTP: 123456
   +234 123 456 7894 → OTP: 123456
   ```
5. Save

## Step 3: Add Android App to Firebase

1. In Firebase Console, click **Add app** → **Android icon**
2. Register app with:
   - Package name: `com.example.parcel_am`
   - App nickname: TravelLink Android
   - Debug signing certificate SHA-1 (see below)

### Getting SHA-1 Certificate

Run this command in terminal:

```bash
# For Windows
cd android
./gradlew signingReport

# For Mac/Linux
cd android
./gradlew signingReport
```

Look for the SHA1 value in the output under `Variant: debug`.

Alternative method using keytool:
```bash
# Default debug keystore location
# Windows:
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Mac/Linux:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

3. Download `google-services.json`
4. Place it in `android/app/` directory

## Step 4: Update Android Configuration

The following files need to be configured (already done in code):
- `android/build.gradle.kts` - Add Google services classpath
- `android/app/build.gradle.kts` - Apply Google services plugin

## Step 5: Firebase App Check Setup (Optional for Production)

1. In Firebase Console, go to **App Check**
2. Register your app with **Play Integrity** for production
3. For debug builds, SafetyNet is automatically configured

## Step 6: Test Configuration

Run the following command to test:
```bash
flutter run
```

The app should:
1. Initialize Firebase successfully
2. Show no Firebase-related errors
3. Be ready for phone authentication implementation

## Important Notes

### For Production Release:
1. Generate release SHA-1 and SHA-256 certificates
2. Add them to Firebase Console
3. Enable App Check with Play Integrity
4. Use proper package name (not com.example)
5. Configure proper app signing

### Security Considerations:
- Never commit `google-services.json` to public repositories
- Use environment-specific Firebase projects
- Implement rate limiting on backend
- Monitor authentication logs regularly

## Troubleshooting

### Common Issues:

1. **SHA-1 mismatch error**
   - Ensure correct SHA-1 is added in Firebase Console
   - Check if using debug or release build

2. **Phone auth not working**
   - Verify phone auth is enabled in Firebase Console
   - Check internet connectivity
   - Ensure correct country code (+234 for Nigeria)

3. **google-services.json not found**
   - Place file in `android/app/` directory
   - Clean and rebuild: `flutter clean && flutter pub get`

## Next Steps

After completing Firebase setup:
1. Initialize Firebase in main.dart ✓
2. Implement phone authentication UI
3. Add authentication BLoC
4. Test with Nigerian phone numbers
5. Set up session persistence