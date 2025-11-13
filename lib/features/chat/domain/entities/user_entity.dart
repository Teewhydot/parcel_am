import 'package:equatable/equatable.dart';

class ChatUserEntity extends Equatable {
  final String id;
  final String name;
  final String? avatar;
  final String? email;
  final bool isOnline;

  const ChatUserEntity({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [id, name, avatar, email, isOnline];
}
