import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/chat.dart';
import '../bloc/chats_list_bloc.dart';

class ChatsListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatsListScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late ChatsListBloc _chatsListBloc;

  @override
  void initState() {
    super.initState();
    _chatsListBloc = ChatsListBloc();
    _chatsListBloc.add(LoadChats(widget.currentUserId));
  }

  @override
  void dispose() {
    _chatsListBloc.close();
    super.dispose();
  }

  String _getOtherParticipantName(Chat chat) {
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
    return chat.participantNames[otherParticipantId] ?? 'Unknown';
  }

  String? _getOtherParticipantAvatar(Chat chat) {
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
    return chat.participantAvatars[otherParticipantId];
  }

  String _getOtherParticipantId(Chat chat) {
    return chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
  }

  int _getUnreadCount(Chat chat) {
    return chat.unreadCount[widget.currentUserId] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Chats', color: AppColors.white),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocBuilder<ChatsListBloc, BaseState<List<Chat>>>(
        bloc: _chatsListBloc,
        builder: (context, state) {
          if (state is LoadingState<List<Chat>>) {
            return Skeletonizer(
              enabled: true,
              child: ListView.separated(
                itemCount: 8,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: AppText.bodyMedium('L', color: AppColors.white),
                    ),
                    title: AppText.bodyLarge('Loading User Name'),
                    subtitle: AppText.bodyMedium('Loading message content here...'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText.bodySmall('12:00'),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.md,
                          ),
                          child: AppText.bodySmall('3', color: AppColors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          if (state is ErrorState<List<Chat>>) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppText.titleLarge('Error loading chats'),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  AppText.bodyMedium(
                    state.errorMessage,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppButton.primary(
                    onPressed: () {
                      _chatsListBloc.add(LoadChats(widget.currentUserId));
                    },
                    child: AppText.bodyMedium('Retry', color: AppColors.white),
                  ),
                ],
              ),
            );
          }

          if (state is LoadedState<List<Chat>>) {
            final chats = state.data ?? [];

            if (chats.isEmpty) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      AppText.titleLarge(
                        'No chats yet',
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      AppText.bodyMedium(
                        'Start a conversation with someone',
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _chatsListBloc.add(LoadChats(widget.currentUserId));
              },
              child: AnimationLimiter(
                child: ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherParticipantName = _getOtherParticipantName(chat);
                    final otherParticipantAvatar = _getOtherParticipantAvatar(chat);
                    final otherParticipantId = _getOtherParticipantId(chat);
                    final unreadCount = _getUnreadCount(chat);
                    final isTyping = chat.isTyping[otherParticipantId] ?? false;

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              backgroundImage: otherParticipantAvatar != null
                                  ? NetworkImage(otherParticipantAvatar)
                                  : null,
                              child: otherParticipantAvatar == null
                                  ? AppText.bodyMedium(
                                      otherParticipantName.isNotEmpty
                                          ? otherParticipantName[0].toUpperCase()
                                          : '?',
                                      color: AppColors.white,
                                    )
                                  : null,
                            ),
                            title: AppText.bodyLarge(
                              otherParticipantName,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                            subtitle: AppText.bodyMedium(
                              isTyping
                                  ? 'typing...'
                                  : chat.lastMessage?.content ?? 'No messages yet',
                              color: isTyping ? AppColors.primary : AppColors.textSecondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (chat.lastMessageTime != null)
                                  AppText.bodySmall(
                                    _formatTime(chat.lastMessageTime!),
                                    color: AppColors.textSecondary,
                                  ),
                                if (unreadCount > 0) ...[
                                  AppSpacing.verticalSpacing(SpacingSize.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: AppRadius.md,
                                    ),
                                    child: AppText.bodySmall(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              sl<NavigationService>().navigateTo(
                                Routes.chat,
                                arguments: {
                                  'chatId': chat.id,
                                  'otherUserId': otherParticipantId,
                                  'otherUserName': otherParticipantName,
                                  'otherUserAvatar': otherParticipantAvatar,
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return _getDayName(time.weekday);
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
