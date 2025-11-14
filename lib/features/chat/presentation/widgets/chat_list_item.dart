import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../travellink/domain/entities/chat/chat_entity.dart';
import '../../../travellink/domain/entities/chat/chat_entity_extensions.dart';

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
    final unreadCount = chat.getUnreadCount(currentUserId);
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
                  ? Text(
                      participantName.isNotEmpty
                          ? participantName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          participantName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageTime != null)
                        Text(
                          timeago.format(chat.lastMessageTime!, locale: 'en_short'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                        child: Text(
                          chat.lastMessage ?? 'No messages yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: unreadCount > 0 ? AppColors.onSurface : AppColors.textSecondary,
                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
