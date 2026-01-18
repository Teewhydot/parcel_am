import 'package:flutter/material.dart';
import 'package:parcel_am/core/theme/app_colors.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/utils/logger.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/user_entity.dart';

extension UserExtensions on BuildContext {
  // Extension method to always fetch the current user's ID
  String? get currentUserId {
    // Assuming there's a UserBloc or AuthCubit that holds the current user info
    final userState = read<AuthCubit>().state;
    Logger.logBasic('Current User id: ${userState.data?.user?.uid}');
    return userState.data?.user?.uid;
  }

  // Extension method to get the current user entity
  UserEntity get user {
    final userState = read<AuthCubit>().state;
    return userState.data?.user ?? UserEntity(
      uid: '',
      displayName: '',
      email: '',
      isVerified: false,
      verificationStatus: '',
      createdAt: DateTime.now(),
      additionalData: const {},
    );
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(message, color: AppColors.white),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

extension NigerianPhoneNumber on String {
  String formatNigerianPhoneNumber() {
    if (startsWith('0')) {
      return '+234${substring(1)}';
    } else if (startsWith('+234')) {
      return this;
    } else {
      return '+234$this';
    }
  }
}

extension ParcelAmMediaQuery on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  double get screenPaddingTop => MediaQuery.of(this).padding.top;

  double get screenPaddingBottom => MediaQuery.of(this).padding.bottom;

  double get screenPaddingLeft => MediaQuery.of(this).padding.left;

  double get screenPaddingRight => MediaQuery.of(this).padding.right;

  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  bool get isSmallScreen => screenWidth < 600;

  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;

  bool get isLargeScreen => screenWidth >= 1200;

  bool get isDarkMode =>
      MediaQuery.of(this).platformBrightness == Brightness.dark;
}

extension WidgetStyling on Widget {
  Widget withPadding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }

  Widget withMargin(EdgeInsetsGeometry margin) {
    return Container(margin: margin, child: this);
  }
}

extension Tappable on Widget {
  Widget onTap(VoidCallback? onTap, {Key? key}) {
    return GestureDetector(key: key, onTap: onTap, child: this);
  }

  Widget onLongPress(VoidCallback? onLongPress, {Key? key}) {
    return GestureDetector(key: key, onLongPress: onLongPress, child: this);
  }
}

// skeletonizer extension for widgets
extension Skeletonizer on Widget {
  Widget skeletonize() {
    return Skeleton.leaf(child: this);
  }
}

extension StringExtensions on String {
  String toSentenceCase() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}

// extension for showing snackbars
extension SnackbarExtensions on BuildContext {
  void showSnackbar({
    String message = "",
    Color color = AppColors.accent,
    int duration = 3,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(message, color: AppColors.white),
        duration: Duration(seconds: duration),
        backgroundColor: color,
      ),
    );
  }
}
