
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_bloc.dart';

extension UserExtensions on BuildContext {
  // Extension method to always fetch the current user's ID
  String? get currentUserId {
    // Assuming there's a UserBloc or AuthBloc that holds the current user info
    final userState = read<AuthBloc>().state;
    Logger.logBasic('Current User id: ${userState.data?.user?.uid}');
        return userState.data?.user?.uid;
  }
  void showErrorMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}