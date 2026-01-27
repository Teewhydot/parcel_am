import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/message.dart';

class MessageOptionsSheet extends StatelessWidget {
  const MessageOptionsSheet({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
  });

  final Message message;
  final String? currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  static Future<void> show(
    BuildContext context, {
    required Message message,
    required String? currentUserId,
    required VoidCallback onReply,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MessageOptionsSheet(
        message: message,
        currentUserId: currentUserId,
        onReply: () {
          Navigator.pop(context);
          onReply();
        },
        onDelete: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingXL,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: AppText.bodyLarge('Reply'),
            onTap: onReply,
          ),
          if (message.senderId == currentUserId)
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: AppText.bodyLarge('Delete', color: AppColors.error),
              onTap: onDelete,
            ),
        ],
      ),
    );
  }
}
