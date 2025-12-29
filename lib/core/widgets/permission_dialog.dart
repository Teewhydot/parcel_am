import 'package:flutter/material.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permission_service/permission_service.dart';
import 'app_spacing.dart';
import '../utils/logger.dart';
import '../helpers/user_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// A reusable dialog to request various app permissions
class PermissionDialog extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final Permission permission;
  final Function() onGranted;
  final Function()? onDenied;
  final bool isMandatory;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
    required this.onGranted,
    this.onDenied,
    this.isMandatory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      elevation: 0,
      backgroundColor: AppColors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: AppColors.white,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Image.asset(icon, height: 60, width: 60),
          AppSpacing.verticalSpacing(SpacingSize.lg),

          // Title
          AppText.centered(title, fontWeight: FontWeight.bold),
          AppSpacing.verticalSpacing(SpacingSize.md),

          // Description
          AppText.titleMedium(description),
          AppSpacing.verticalSpacing(SpacingSize.xxl),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isMandatory)
                Expanded(
                  child: AppButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onDenied != null) {
                        onDenied!();
                      }
                    },
                    child: AppText.centered("Reject"),
                  ),
                ),
              if (!isMandatory) AppSpacing.horizontalSpacing(SpacingSize.lg),
              Expanded(
                child: AppButton(
                  child: AppText.centered("Grant"),
                  onPressed: () async {
                    final permissionService = PermissionService();
                    bool isGranted = false;

                    // Handle different permission types
                    if (permission == Permission.location) {
                      isGranted = await permissionService
                          .requestLocationPermission();
                    } else {
                      final status = await permission.request();
                      isGranted = status.isGranted;
                      // Save the permission status
                    }

                    if (isGranted) {
                      Logger.logSuccess(
                        'Permission granted: ${permission.toString()}',
                      );
                      Navigator.pop(context, true);
                      onGranted();
                    } else if (isMandatory) {
                      // If permission is mandatory but denied, show a message
                      context.showSnackbar(
                        message: 'This permission is required to use this feature.',
                        color: AppColors.error,
                      );
                    } else {
                      Navigator.pop(context, false);
                      if (onDenied != null) {
                        onDenied!();
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show permission dialog static method
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    required String icon,
    required Permission permission,
    required Function() onGranted,
    Function()? onDenied,
    bool isMandatory = false,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        return PermissionDialog(
          title: title,
          description: description,
          icon: icon,
          permission: permission,
          onGranted: onGranted,
          onDenied: onDenied,
          isMandatory: isMandatory,
        );
      },
    );
  }
}
