# SHA-1 Certificate Generation Guide

## Method 1: Using Gradle (Recommended)

Open terminal in the project root and run:

```bash
cd android
./gradlew signingReport
```

Look for output similar to:
```
Variant: debug
Config: debug
Store: C:\Users\[username]\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy the **SHA1** value.

## Method 2: Using Keytool

### Windows:
```cmd
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Mac/Linux:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Method 3: Using Android Studio

1. Open Android Studio
2. Open your project
3. Navigate to **View** → **Tool Windows** → **Gradle**
4. Expand **android** → **signingReport**
5. Double-click on **signingReport**
6. Check the **Run** tab for SHA1 output

## What to do with SHA-1:

1. Copy the SHA1 value (format: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX)
2. Go to Firebase Console
3. Project Settings → General → Your Apps → Android App
4. Add the SHA1 certificate fingerprint
5. Download updated `google-services.json`
6. Replace the file in `android/app/google-services.json`

## For Production Release:

When creating release builds, you'll need to:

1. Generate release signing key:
```bash
keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

2. Get release SHA1:
```bash
keytool -list -v -keystore release-key.keystore -alias release
```

3. Add both debug and release SHA1 to Firebase Console

## Troubleshooting:

### If gradlew doesn't work:
- Ensure you're in the `android` directory
- On Windows, try `gradlew.bat signingReport`
- Make sure Android SDK is properly installed
- Try running `flutter doctor` to check setup

### If keytool command not found:
- Make sure Java JDK is installed and in PATH
- On Windows, use full path: `"C:\Program Files\Java\jdk-xx\bin\keytool"`

### Common SHA1 for debug builds:
The debug keystore is usually the same across machines:
```
SHA1: 58:9D:F1:73:89:87:5A:1B:17:D7:89:A9:CB:58:4A:7C:94:07:47:75
```

But it's better to generate and use your own for security.