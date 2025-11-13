import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_entity.dart';
import 'presence_indicator.dart';

class ChatListItem extends StatelessWidget {
  final ChatEntity chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatListItem({
    Key? key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: chat.participantAvatar != null
                      ? NetworkImage(chat.participantAvatar!)
                      : null,
                  child: chat.participantAvatar == null
                      ? Text(
                          chat.participantName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: PresenceIndicator(status: chat.presenceStatus),
                ),
              ],
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
                          chat.participantName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageTime != null)
                        Text(
                          timeago.format(chat.lastMessageTime!, locale: 'en_short'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: chat.unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (chat.isMuted)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.notifications_off,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (chat.presenceStatus == PresenceStatus.typing)
                        Expanded(
                          child: Text(
                            'typing...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.info,
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'No messages yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: chat.unreadCount > 0 ? AppColors.onSurface : AppColors.textSecondary,
                                  fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
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
