import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

/// A page of messages stored as a single Firestore document.
///
/// This approach reduces Firestore writes by appending messages to an array
/// within a single document rather than creating a new document per message.
///
/// Structure: chats/{chatId}/pages/{pageId}
/// - Each page contains up to [maxMessagesPerPage] messages
/// - When a page reaches capacity, a new page is created
/// - Pages are ordered by pageNumber (descending = newest first)
class MessagePageModel {
  /// Maximum messages per page (conservative limit to stay well under 1MB doc limit)
  static const int maxMessagesPerPage = 100;

  /// Approximate max bytes per page (leave headroom under 1MB Firestore limit)
  static const int maxBytesPerPage = 800000; // ~800KB

  /// Page document ID
  final String id;

  /// The chat this page belongs to
  final String chatId;

  /// Page number (0 = oldest, higher = newer)
  final int pageNumber;

  /// List of messages in this page
  final List<MessageModel> messages;

  /// Current message count in this page
  final int messageCount;

  /// Approximate bytes used by this page (for size tracking)
  final int bytesUsed;

  /// Whether there are older pages before this one
  final bool hasOlderPages;

  /// When this page was created
  final DateTime createdAt;

  /// When this page was last updated
  final DateTime updatedAt;

  const MessagePageModel({
    required this.id,
    required this.chatId,
    required this.pageNumber,
    required this.messages,
    required this.messageCount,
    required this.bytesUsed,
    required this.hasOlderPages,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this page can accept more messages
  bool get canAcceptMoreMessages =>
      messageCount < maxMessagesPerPage && bytesUsed < maxBytesPerPage;

  /// Estimate bytes for a message (rough calculation)
  static int estimateMessageBytes(MessageModel message) {
    // Rough estimate: JSON serialization overhead + content length
    final json = message.toJson();
    return json.toString().length * 2; // UTF-16 chars ~2 bytes each
  }

  factory MessagePageModel.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return MessagePageModel(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String,
      pageNumber: json['pageNumber'] as int? ?? 0,
      messages: messages,
      messageCount: json['messageCount'] as int? ?? messages.length,
      bytesUsed: json['bytesUsed'] as int? ?? 0,
      hasOlderPages: json['hasOlderPages'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MessagePageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return MessagePageModel.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'pageNumber': pageNumber,
      'messages': messages.map((m) => m.toJson()).toList(),
      'messageCount': messageCount,
      'bytesUsed': bytesUsed,
      'hasOlderPages': hasOlderPages,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a new empty page
  factory MessagePageModel.empty({
    required String chatId,
    required int pageNumber,
    bool hasOlderPages = false,
  }) {
    final now = DateTime.now();
    return MessagePageModel(
      id: '', // Will be assigned by Firestore
      chatId: chatId,
      pageNumber: pageNumber,
      messages: [],
      messageCount: 0,
      bytesUsed: 0,
      hasOlderPages: hasOlderPages,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a copy with a new message appended
  MessagePageModel copyWithNewMessage(MessageModel message) {
    final newMessages = [...messages, message];
    final messageBytes = estimateMessageBytes(message);
    return MessagePageModel(
      id: id,
      chatId: chatId,
      pageNumber: pageNumber,
      messages: newMessages,
      messageCount: newMessages.length,
      bytesUsed: bytesUsed + messageBytes,
      hasOlderPages: hasOlderPages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
