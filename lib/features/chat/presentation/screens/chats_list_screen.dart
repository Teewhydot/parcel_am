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
import '../widgets/chat_list_tile.dart';

/// Screen displaying the list of user's chat conversations.
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

  void _navigateToChat(Chat chat) {
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => '',
    );
    final otherParticipantName =
        chat.participantNames[otherParticipantId] ?? 'Unknown';
    final otherParticipantAvatar = chat.participantAvatars[otherParticipantId];

    sl<NavigationService>().navigateTo(
      Routes.chat,
      arguments: {
        'chatId': chat.id,
        'otherUserId': otherParticipantId,
        'otherUserName': otherParticipantName,
        'otherUserAvatar': otherParticipantAvatar,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: BlocBuilder<ChatsListBloc, BaseState<List<Chat>>>(
        bloc: _chatsListBloc,
        builder: (context, state) {
          if (state is LoadingState<List<Chat>>) {
            return _buildLoadingState();
          }

          if (state is ErrorState<List<Chat>>) {
            return _buildErrorState(state.errorMessage);
          }

          if (state is LoadedState<List<Chat>>) {
            final chats = state.data ?? [];
            if (chats.isEmpty) {
              return _buildEmptyState();
            }
            return _buildChatsList(chats);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleLarge(
            'Messages',
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Search functionality
          },
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.onSurface,
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.xs),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surface,
                ),
                AppSpacing.horizontalSpacing(SpacingSize.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.sm,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.sm,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.sm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
            AppText.titleMedium(
              'Something went wrong',
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyMedium(
              errorMessage,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
            AppButton.primary(
              onPressed: () {
                _chatsListBloc.add(LoadChats(widget.currentUserId));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 20),
                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                  AppText.bodyMedium('Try Again', color: AppColors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.xl),
            AppText.titleLarge(
              'No conversations yet',
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpacing(SpacingSize.sm),
            AppText.bodyMedium(
              'Start chatting with someone by accepting or creating a delivery request',
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList(List<Chat> chats) {
    return RefreshIndicator(
      onRefresh: () async {
        _chatsListBloc.add(LoadChats(widget.currentUserId));
      },
      color: AppColors.primary,
      child: AnimationLimiter(
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: chats.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(left: 88),
            child: Divider(
              height: 1,
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
          ),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: ChatListTile(
                    chat: chat,
                    currentUserId: widget.currentUserId,
                    onTap: () => _navigateToChat(chat),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
