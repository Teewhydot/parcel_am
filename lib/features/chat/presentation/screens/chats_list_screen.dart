import 'package:flutter/material.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/chat.dart';
import '../bloc/chats_list_bloc.dart';
import '../widgets/chats_list/chats_list_app_bar.dart';
import '../widgets/chats_list/chats_loading_state.dart';
import '../widgets/chats_list/chats_error_state.dart';
import '../widgets/chats_list/chats_empty_state.dart';
import '../widgets/chats_list/chats_list_view.dart';

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
      appBar: const ChatsListAppBar(),
      body: BlocManager<ChatsListBloc, BaseState<List<Chat>>>(
        bloc: _chatsListBloc,
        showLoadingIndicator: false,
        showResultErrorNotifications: false,
        builder: (context, state) {
          if (state is LoadingState<List<Chat>>) {
            return const ChatsLoadingState();
          }

          if (state is ErrorState<List<Chat>>) {
            return ChatsErrorState(
              errorMessage: state.errorMessage,
              onRetry: () {
                _chatsListBloc.add(LoadChats(widget.currentUserId));
              },
            );
          }

          if (state is LoadedState<List<Chat>>) {
            final chats = state.data ?? [];
            if (chats.isEmpty) {
              return const ChatsEmptyState();
            }
            return ChatsListView(
              chats: chats,
              currentUserId: widget.currentUserId,
              onChatTap: _navigateToChat,
              onRefresh: () async {
                _chatsListBloc.add(LoadChats(widget.currentUserId));
              },
            );
          }

          return const SizedBox.shrink();
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
