class AiChatMessage {
  final String id;
  final String userId;
  final String sessionId;
  final String role; // 'user' hoặc 'assistant'
  final String content;
  final DateTime createdAt;

  AiChatMessage({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    /// 🔥 detect message type
    final isUserMessage = json['user_message'] != null;

    return AiChatMessage(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      sessionId: json['user_id']?.toString() ?? '', // dùng tạm userId
      role: isUserMessage ? 'user' : 'assistant',
      content: isUserMessage
          ? json['user_message'] ?? ''
          : json['ai_reply'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_message': role == 'user' ? content : null,
      'ai_reply': role == 'assistant' ? content : null,
    };
  }
}