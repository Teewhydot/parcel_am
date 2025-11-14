import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_entity.dart';

class PresenceIndicator extends StatelessWidget {
  final PresenceStatus status;
  final double size;

  const PresenceIndicator({
    super.key,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: status == PresenceStatus.typing
          ? Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : null,
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case PresenceStatus.online:
        return AppColors.success;
      case PresenceStatus.typing:
        return AppColors.info;
      case PresenceStatus.offline:
        return AppColors.textSecondary;
    }
  }
}
