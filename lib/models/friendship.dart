class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  /// Thông tin bạn bè (join từ profiles)
  final String? friendName;
  final String? friendEmail;
  final String? friendAvatar;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.friendName,
    this.friendEmail,
    this.friendAvatar,
  });

  factory Friendship.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    /// Xác định ai là "bạn" (không phải mình)
    final isUserSender = json['user_id'] == currentUserId;
    final profile = isUserSender ? json['friend_profile'] : json['user_profile'];

    return Friendship(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      friendName: profile?['full_name'],
      friendEmail: profile?['email'],
      friendAvatar: profile?['avatar_url'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}
