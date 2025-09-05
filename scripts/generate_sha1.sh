#!/bin/bash

# Generate SHA-1 certificate for Firebase setup
# This script helps you get the SHA-1 fingerprint needed for Firebase Console

echo "🔐 TravelLink Firebase SHA-1 Generator"
echo "====================================="
echo ""

# Check if we're in the right directory
if [ ! -d "android" ]; then
    echo "❌ Error: Run this script from your Flutter project root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: Your project should have an 'android' folder"
    exit 1
fi

echo "📱 Generating SHA-1 fingerprints for Firebase setup..."
echo ""

# Method 1: Using Gradle (Recommended)
echo "🔧 Method 1: Using Gradle Wrapper"
echo "--------------------------------"

if [ -f "android/gradlew" ]; then
    echo "Running: ./gradlew signingReport"
    cd android
    chmod +x gradlew
    ./gradlew signingReport | grep -A 3 -B 2 "SHA1"
    cd ..
    echo ""
else
    echo "⚠️  Gradle wrapper not found, trying alternative methods..."
    echo ""
fi

# Method 2: Using keytool
echo "🔑 Method 2: Using Keytool"
echo "-------------------------"

# Check if keytool exists
if command -v keytool &> /dev/null; then
    echo "Checking debug keystore..."
    
    # Default debug keystore location
    DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
    
    if [ -f "$DEBUG_KEYSTORE" ]; then
        echo "Found debug keystore: $DEBUG_KEYSTORE"
        echo "SHA-1 fingerprint:"
        keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android | grep SHA1
    else
        echo "❌ Debug keystore not found at: $DEBUG_KEYSTORE"
        echo "   You may need to build your app first: flutter build apk --debug"
    fi
else
    echo "❌ keytool not found. Please install Java SDK."
fi

echo ""
echo "📋 Instructions:"
echo "================"
echo ""
echo "1. Copy the SHA1 fingerprint from above"
echo "2. Go to Firebase Console: https://console.firebase.google.com"
echo "3. Select your project: travellink-parcel-delivery"
echo "4. Go to Project Settings → Your Apps → Android App"
echo "5. Add the SHA1 certificate fingerprint"
echo ""
echo "🚀 For Production:"
echo "- Generate a release keystore"
echo "- Add the release SHA1 to Firebase Console"
echo "- Keep your keystore secure!"
echo ""
echo "Next: Run 'dart scripts/firebase_setup_check.dart' to verify your setup"