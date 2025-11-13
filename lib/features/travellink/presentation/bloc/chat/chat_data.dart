import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat/chat_entity.dart';

class ChatData extends Equatable {
  final List<ChatEntity> chats;
  final String? currentUserId;
  final bool isListening;

  const ChatData({
    this.chats = const [],
    this.currentUserId,
    this.isListening = false,
  });

  ChatData copyWith({
    List<ChatEntity>? chats,
    String? currentUserId,
    bool? isListening,
  }) {
    return ChatData(
      chats: chats ?? this.chats,
      currentUserId: currentUserId ?? this.currentUserId,
      isListening: isListening ?? this.isListening,
    );
  }

  @override
  List<Object?> get props => [chats, currentUserId, isListening];
}
