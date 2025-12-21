import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/chat_entity.dart';

class ChatListItem extends StatelessWidget {
  final ChatEntity chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String currentUserId;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = chat.unreadCount;
    final participantName = chat.participantName;
    final participantAvatar = chat.participantAvatar;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: participantAvatar != null
                  ? NetworkImage(participantAvatar)
                  : null,
              child: participantAvatar == null
                  ? AppText(
                      participantName.isNotEmpty
                          ? participantName[0].toUpperCase()
                          : '?',
                      variant: TextVariant.titleLarge,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            AppSpacing.horizontalSpacing(SpacingSize.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText.titleMedium(
                          participantName,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageTime != null)
                        AppText.bodySmall(
                          timeago.format(chat.lastMessageTime!, locale: 'en_short'),
                          color: unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                    ],
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xs),
                  Row(
                    children: [
                      if (chat.isMuted)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.notifications_off,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Expanded(
                        child: AppText.bodyMedium(
                          chat.lastMessage ?? 'No messages yet',
                          color: unreadCount > 0 ? AppColors.onSurface : AppColors.textSecondary,
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        AppSpacing.horizontalSpacing(SpacingSize.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppText.bodySmall(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
