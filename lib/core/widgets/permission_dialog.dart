import 'package:flutter/material.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/app_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permission_service/permission_service.dart';
import '../utils/logger.dart';
import '../helpers/user_extensions.dart';
import '../theme/app_colors.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Image.asset(icon, height: 60, width: 60),
          const SizedBox(height: 16),

          // Title
          AppText.centered(title, fontWeight: FontWeight.bold),
          const SizedBox(height: 12),

          // Description
          AppText.titleMedium(description),
          const SizedBox(height: 24),

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
              if (!isMandatory) const SizedBox(width: 16),
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
