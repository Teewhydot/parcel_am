#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Firebase Setup Verification Script for TravelLink
/// 
/// This script checks your local Firebase configuration to ensure
/// everything is set up correctly for phone authentication.

void main() async {
  print('🔥 TravelLink Firebase Setup Checker');
  print('=====================================\n');

  final checks = [
    _checkGoogleServicesJson,
    _checkAndroidConfiguration,
    _checkFirebaseConfig,
    _checkPhoneAuthConfig,
    _checkBuildGradle,
    _checkPubspecDependencies,
  ];

  bool allPassed = true;
  
  for (final check in checks) {
    final result = await check();
    if (!result) allPassed = false;
    print(''); // Add spacing
  }

  print('\n📋 SUMMARY');
  print('==========');
  if (allPassed) {
    print('✅ All checks passed! Your Firebase setup looks good.');
    print('🚀 You can now run: flutter run');
  } else {
    print('❌ Some checks failed. Please fix the issues above.');
    print('📖 See docs/FIREBASE_SERVER_SETUP.md for detailed instructions.');
  }
  
  print('\n📱 Next Steps:');
  print('1. Complete Firebase Console setup');
  print('2. Add SHA-1 certificates');
  print('3. Test with debug build');
  print('4. Configure test phone numbers');
}

Future<bool> _checkGoogleServicesJson() async {
  print('📄 Checking google-services.json...');
  
  final file = File('android/app/google-services.json');
  if (!await file.exists()) {
    print('❌ google-services.json not found in android/app/');
    print('   Download it from Firebase Console → Project Settings → Your Apps');
    return false;
  }

  try {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    
    final projectId = json['project_info']?['project_id'];
    final packageName = json['client']?[0]?['client_info']?['android_client_info']?['package_name'];
    
    if (projectId == null || packageName == null) {
      print('❌ Invalid google-services.json format');
      return false;
    }
    
    print('✅ Found google-services.json');
    print('   Project ID: $projectId');
    print('   Package: $packageName');
    
    if (packageName != 'com.example.parcel_am') {
      print('⚠️  Warning: Package name mismatch. Expected: com.example.parcel_am');
    }
    
    return true;
  } catch (e) {
    print('❌ Error reading google-services.json: $e');
    return false;
  }
}

Future<bool> _checkAndroidConfiguration() async {
  print('🤖 Checking Android configuration...');
  
  // Check build.gradle (app level)
  final appBuildGradle = File('android/app/build.gradle');
  if (!await appBuildGradle.exists()) {
    print('❌ android/app/build.gradle not found');
    return false;
  }

  final buildGradleContent = await appBuildGradle.readAsString();
  
  final hasGoogleServicesPlugin = buildGradleContent.contains('com.google.gms.google-services');
  final hasApplicationId = buildGradleContent.contains('applicationId "com.example.parcel_am"');
  
  if (!hasGoogleServicesPlugin) {
    print('❌ Google Services plugin not applied in android/app/build.gradle');
    print('   Add: apply plugin: \'com.google.gms.google-services\'');
    return false;
  }
  
  if (!hasApplicationId) {
    print('⚠️  Warning: Application ID might not match Firebase configuration');
  }

  // Check project level build.gradle
  final projectBuildGradle = File('android/build.gradle');
  if (await projectBuildGradle.exists()) {
    final projectContent = await projectBuildGradle.readAsString();
    final hasGoogleServicesClasspath = projectContent.contains('com.google.gms:google-services');
    
    if (!hasGoogleServicesClasspath) {
      print('❌ Google Services classpath missing in android/build.gradle');
      print('   Add: classpath \'com.google.gms:google-services:4.3.15\'');
      return false;
    }
  }

  print('✅ Android configuration looks good');
  return true;
}

Future<bool> _checkFirebaseConfig() async {
  print('🔧 Checking Firebase configuration files...');
  
  final firebaseConfig = File('lib/core/config/firebase_config.dart');
  if (!await firebaseConfig.exists()) {
    print('❌ firebase_config.dart not found');
    return false;
  }

  final content = await firebaseConfig.readAsString();
  
  final hasNigerianConfig = content.contains('nigeriaConfig');
  final hasTestOtpCode = content.contains('testOtpCode');
  final hasValidPrefixes = content.contains('valid_prefixes');
  
  if (!hasNigerianConfig || !hasTestOtpCode || !hasValidPrefixes) {
    print('❌ Firebase configuration incomplete');
    return false;
  }

  print('✅ Firebase configuration found');
  
  // Check for common Nigerian prefixes
  final commonPrefixes = ['803', '806', '813', '816', '818', '708', '803'];
  bool hasCommonPrefixes = false;
  
  for (final prefix in commonPrefixes) {
    if (content.contains(prefix)) {
      hasCommonPrefixes = true;
      break;
    }
  }
  
  if (hasCommonPrefixes) {
    print('✅ Nigerian phone prefixes configured');
  } else {
    print('⚠️  Warning: Common Nigerian prefixes might be missing');
  }
  
  return true;
}

Future<bool> _checkPhoneAuthConfig() async {
  print('📞 Checking phone authentication setup...');
  
  final authBloc = File('lib/features/travellink/presentation/bloc/auth/auth_bloc.dart');
  final authRepository = File('lib/features/travellink/data/repositories/auth_repository.dart');
  final sessionManager = File('lib/core/services/session/session_manager.dart');
  
  final files = [
    ('AuthBloc', authBloc),
    ('AuthRepository', authRepository),
    ('SessionManager', sessionManager),
  ];
  
  bool allExist = true;
  
  for (final (name, file) in files) {
    if (await file.exists()) {
      print('✅ $name found');
    } else {
      print('❌ $name missing: ${file.path}');
      allExist = false;
    }
  }
  
  return allExist;
}

Future<bool> _checkBuildGradle() async {
  print('🏗️ Checking build.gradle configuration...');
  
  final appBuildGradle = File('android/app/build.gradle');
  if (!await appBuildGradle.exists()) {
    print('❌ android/app/build.gradle not found');
    return false;
  }
  
  final content = await appBuildGradle.readAsString();
  
  final checks = [
    ('minSdkVersion 19', content.contains('minSdkVersion 19') || content.contains('minSdkVersion 21')),
    ('compileSdkVersion 34', content.contains('compileSdkVersion 34') || content.contains('compileSdk 34')),
    ('multiDexEnabled true', content.contains('multiDexEnabled true')),
  ];
  
  bool allPassed = true;
  
  for (final (check, passed) in checks) {
    if (passed) {
      print('✅ $check');
    } else {
      print('⚠️  $check - might need attention');
    }
  }
  
  return allPassed;
}

Future<bool> _checkPubspecDependencies() async {
  print('📦 Checking pubspec.yaml dependencies...');
  
  final pubspec = File('pubspec.yaml');
  if (!await pubspec.exists()) {
    print('❌ pubspec.yaml not found');
    return false;
  }
  
  final content = await pubspec.readAsString();
  
  final requiredDeps = [
    'firebase_core',
    'firebase_auth',
    'flutter_bloc',
    'flutter_secure_storage',
    'get',
  ];
  
  bool allFound = true;
  
  for (final dep in requiredDeps) {
    if (content.contains('$dep:')) {
      print('✅ $dep');
    } else {
      print('❌ $dep missing');
      allFound = false;
    }
  }
  
  return allFound;
}