import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../widgets/bottom_navigation.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, BaseState<AuthData>, String>(
      selector: (state) {
        if (state is LoadedState<AuthData>) {
          return state.data?.user?.uid ?? '';
        }
        return '';
      },
      builder: (context, userId) {
        return AppScaffold(
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
              child: userId.isEmpty
                  ? _buildEmptyState()
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('participants', arrayContains: userId)
                          .orderBy('lastMessageTime', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState();
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final chats = snapshot.data?.docs ?? [];

                        if (chats.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chatData = chats[index].data() as Map<String, dynamic>;
                            final chatId = chats[index].id;
                            final participants = List<String>.from(chatData['participants'] ?? []);
                            final otherUserId = participants.firstWhere(
                              (id) => id != userId,
                              orElse: () => '',
                            );

                            return _ChatListItem(
                              chatId: chatId,
                              otherUserId: otherUserId,
                              lastMessage: chatData['lastMessage'] ?? '',
                              lastMessageTime: chatData['lastMessageTime'] as Timestamp?,
                              unreadCount: (chatData['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
        );
      },
    );
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyLarge('Error loading chats', color: AppColors.error),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final int unreadCount;

  const _ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] ?? 'Unknown User';
        final isOnline = userData?['presence']?['isOnline'] ?? false;

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
                      displayName[0].toUpperCase(),
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
                      lastMessage,
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
      },
    );
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
