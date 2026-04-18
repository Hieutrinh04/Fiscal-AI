class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String currency;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.currency = 'VND',
    this.language = 'vi',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      currency: json['currency'] as String? ?? 'VND',
      language: json['language'] as String? ?? 'vi',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'currency': currency,
      'language': language,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? currency,
    String? language,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
