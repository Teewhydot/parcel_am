import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/chat.dart';
import '../../../services/typing_service.dart';
import '../../bloc/chat_cubit.dart';

class ChatAppBarContent extends StatelessWidget {
  const ChatAppBarContent({
    super.key,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.chatId,
    required this.otherUserId,
    required this.currentUserId,
    required this.typingService,
  });

  final String otherUserName;
  final String? otherUserAvatar;
  final String chatId;
  final String otherUserId;
  final String? currentUserId;
  final TypingService typingService;

  String _getOnlineStatusFromChat(Chat? chat) {
    if (chat == null) return '';

    final lastSeen = chat.lastSeen[otherUserId];
    if (lastSeen == null) return 'offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) return 'online';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.surfaceVariant,
          backgroundImage:
              otherUserAvatar != null ? NetworkImage(otherUserAvatar!) : null,
          child: otherUserAvatar == null
              ? AppText.bodyMedium(
                  otherUserName[0].toUpperCase(),
                  color: AppColors.white,
                )
              : null,
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyLarge(otherUserName),
              StreamBuilder<bool>(
                stream: typingService.watchUserTyping(
                  chatId,
                  otherUserId,
                  currentUserId ?? '',
                ),
                builder: (context, typingSnapshot) {
                  final isTyping = typingSnapshot.data ?? false;

                  if (isTyping) {
                    return AppText.bodySmall(
                      'typing...',
                      color: AppColors.success,
                    );
                  }

                  return StreamBuilder<Either<Failure, Chat>>(
                    stream: context.read<ChatCubit>().watchChat(chatId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.fold(
                          (failure) => const SizedBox.shrink(),
                          (chat) {
                            final status = _getOnlineStatusFromChat(chat);
                            return AppText.bodySmall(
                              status,
                              color: status == 'online'
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
