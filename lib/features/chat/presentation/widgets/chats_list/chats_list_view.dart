import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat.dart';
import '../chat_list_tile.dart';

/// Animated list view of chat conversations.
///
/// Displays chats with staggered slide and fade animations,
/// wrapped in a pull-to-refresh indicator.
class ChatsListView extends StatelessWidget {
  final List<Chat> chats;
  final String currentUserId;
  final void Function(Chat chat) onChatTap;
  final Future<void> Function() onRefresh;

  const ChatsListView({
    super.key,
    required this.chats,
    required this.currentUserId,
    required this.onChatTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: chats.length,
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
                    currentUserId: currentUserId,
                    onTap: () => onChatTap(chat),
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
