#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Firebase Setup Verification Script for Parcel AM
/// 
/// This script checks your local Firebase configuration to ensure
/// everything is set up correctly for phone authentication.

void main() async {

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
    // Add spacing
  }

  if (allPassed) {
  } else {
  }
  
}

Future<bool> _checkGoogleServicesJson() async {
  
  final file = File('android/app/google-services.json');
  if (!await file.exists()) {
    return false;
  }

  try {
    final content = await file.readAsString();
    final json = jsonDecode(content);
    
    final projectId = json['project_info']?['project_id'];
    final packageName = json['client']?[0]?['client_info']?['android_client_info']?['package_name'];
    
    if (projectId == null || packageName == null) {
      return false;
    }
    
    
    if (packageName != 'com.example.parcel_am') {
    }
    
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> _checkAndroidConfiguration() async {
  
  // Check build.gradle (app level)
  final appBuildGradle = File('android/app/build.gradle');
  if (!await appBuildGradle.exists()) {
    return false;
  }

  final buildGradleContent = await appBuildGradle.readAsString();
  
  final hasGoogleServicesPlugin = buildGradleContent.contains('com.google.gms.google-services');
  final hasApplicationId = buildGradleContent.contains('applicationId "com.example.parcel_am"');
  
  if (!hasGoogleServicesPlugin) {
    return false;
  }
  
  if (!hasApplicationId) {
  }

  // Check project level build.gradle
  final projectBuildGradle = File('android/build.gradle');
  if (await projectBuildGradle.exists()) {
    final projectContent = await projectBuildGradle.readAsString();
    final hasGoogleServicesClasspath = projectContent.contains('com.google.gms:google-services');
    
    if (!hasGoogleServicesClasspath) {
      return false;
    }
  }

  return true;
}

Future<bool> _checkFirebaseConfig() async {
  
  final firebaseConfig = File('lib/core/config/firebase_config.dart');
  if (!await firebaseConfig.exists()) {
    return false;
  }

  final content = await firebaseConfig.readAsString();
  
  final hasNigerianConfig = content.contains('nigeriaConfig');
  final hasTestOtpCode = content.contains('testOtpCode');
  final hasValidPrefixes = content.contains('valid_prefixes');
  
  if (!hasNigerianConfig || !hasTestOtpCode || !hasValidPrefixes) {
    return false;
  }

  
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
  } else {
  }
  
  return true;
}

Future<bool> _checkPhoneAuthConfig() async {
  
  final authBloc = File('lib/features/parcel_am_core/presentation/bloc/auth/auth_bloc.dart');
  final authRepository = File('lib/features/parcel_am_core/data/repositories/auth_repository.dart');
  final sessionManager = File('lib/core/services/session/session_manager.dart');
  
  final files = [
    ('AuthBloc', authBloc),
    ('AuthRepository', authRepository),
    ('SessionManager', sessionManager),
  ];
  
  bool allExist = true;
  
  for (final (name, file) in files) {
    if (await file.exists()) {
    } else {
      allExist = false;
    }
  }
  
  return allExist;
}

Future<bool> _checkBuildGradle() async {
  
  final appBuildGradle = File('android/app/build.gradle');
  if (!await appBuildGradle.exists()) {
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
    } else {
    }
  }
  
  return allPassed;
}

Future<bool> _checkPubspecDependencies() async {
  
  final pubspec = File('pubspec.yaml');
  if (!await pubspec.exists()) {
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
    } else {
      allFound = false;
    }
  }
  
  return allFound;
}