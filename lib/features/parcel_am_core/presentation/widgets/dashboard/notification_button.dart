import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/helpers/user_extensions.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.black,
          ),
          onPressed: () {
            sl<NavigationService>().navigateTo(
              Routes.notifications,
              arguments: context.currentUserId ?? '',
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: AppContainer(
            width: 8,
            height: 8,
            color: AppColors.accent,
            borderRadius: AppRadius.xs,
          ),
        ),
      ],
    );
  }
}
