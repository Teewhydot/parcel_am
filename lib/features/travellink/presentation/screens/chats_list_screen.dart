import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../chat/presentation/bloc/chats_list_bloc.dart';
import '../../../chat/domain/entities/chat.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../widgets/bottom_navigation.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late ChatsListBloc _chatsListBloc;

  @override
  void initState() {
    super.initState();
    _chatsListBloc = sl<ChatsListBloc>();

    // Load chats for current user
    final authState = context.read<AuthBloc>().state;
    if (authState is LoadedState<AuthData>) {
      final userId = authState.data?.user?.uid ?? '';
      if (userId.isNotEmpty) {
        _chatsListBloc.add(LoadChats(userId));
      }
    }
  }

  @override
  void dispose() {
    _chatsListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatsListBloc,
      child: AppScaffold(
        hasGradientBackground: true,
        bottomNavigationBar: const BottomNavigation(currentIndex: 2),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: AppContainer(
                variant: ContainerVariant.surface,
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                padding: AppSpacing.paddingXL,
                child: BlocBuilder<ChatsListBloc, ChatsListState>(
                  builder: (context, state) {
                    if (state is ChatsListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ChatsListError) {
                      return _buildErrorState(state.message);
                    }

                    if (state is ChatsListLoaded) {
                      final chats = state.chats;

                      if (chats.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];

                          // Get other user ID from participants
                          final authState = context.read<AuthBloc>().state;
                          final currentUserId = authState is LoadedState<AuthData>
                              ? authState.data?.user?.uid ?? ''
                              : '';

                          final otherUserId = chat.participantIds.firstWhere(
                            (id) => id != currentUserId,
                            orElse: () => chat.participantIds.isNotEmpty
                                ? chat.participantIds.first
                                : '',
                          );

                          return _ChatListItem(
                            chatId: chat.id,
                            otherUserId: otherUserId,
                            displayName: chat.participantNames[otherUserId] ?? 'Unknown User',
                            lastMessage: chat.lastMessage?.content ?? '',
                            lastMessageTime: chat.lastMessageTime,
                            unreadCount: chat.unreadCount[currentUserId] ?? 0,
                            isOnline: _isUserOnline(chat, otherUserId),
                          );
                        },
                      );
                    }

                    return _buildEmptyState();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isUserOnline(Chat chat, String userId) {
    final lastSeen = chat.lastSeen[userId];
    if (lastSeen == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    return difference.inMinutes < 5;
  }

  Widget _buildHeader(BuildContext context) {
    return AppContainer(
      padding: AppSpacing.paddingXL,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          AppText.headlineSmall(
            'Messages',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.onSurfaceVariant),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyLarge('No messages yet', color: AppColors.onSurfaceVariant),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            'Start a conversation with your delivery partners',
            color: AppColors.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyLarge('Error loading chats', color: AppColors.error),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodySmall(message, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String displayName;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  const _ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.displayName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return AppContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.paddingMD,
      variant: ContainerVariant.surface,
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        sl<NavigationService>().navigateTo(
          Routes.chat,
          arguments: {'chatId': chatId, 'otherUserId': otherUserId},
        );
      },
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(
                  displayName,
                  fontWeight: FontWeight.w600,
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                  color: AppColors.onSurfaceVariant,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessageTime != null)
                AppText.labelSmall(
                  _formatTime(lastMessageTime!),
                  color: AppColors.onSurfaceVariant,
                ),
              if (unreadCount > 0) ...[
                AppSpacing.verticalSpacing(SpacingSize.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AppText.labelSmall(
                    unreadCount.toString(),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
