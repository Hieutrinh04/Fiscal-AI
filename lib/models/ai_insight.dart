class AiInsight {
  final String id;
  final String userId;
  final String type;
  final String content;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  AiInsight({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] ?? 'general',
      content: json['content'] ?? '',
      metadata: json['data'] as Map<String, dynamic>?, // 🔥 FIX
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'content': content,
      'data': metadata, // 🔥 FIX đồng bộ
      'is_read': isRead,
    };
  }

  AiInsight copyWith({bool? isRead}) {
    return AiInsight(
      id: id,
      userId: userId,
      type: type,
      content: content,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}