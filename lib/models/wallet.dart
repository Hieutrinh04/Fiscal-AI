class Wallet {
  final String id;
  final String userId;
  final String name;
  final String type;
  final int balance;
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    this.type = 'Tiền mặt',
    this.balance = 0,
    this.icon = '💳',
    this.color = '#3B82F6',
    this.isDefault = false,
    required this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'Tiền mặt', // Vẫn giữ để đề phòng sau này DB có
      balance: json['balance'] as int? ?? 0,
      icon: json['icon'] as String? ?? '💳',
      color: json['color'] as String? ?? '#3B82F6',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      // 'type': type, // Tạm thời comment lại vì DB chưa có cột này
      'balance': balance,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }

  Wallet copyWith({
    String? name,
    String? type,
    int? balance,
    String? icon,
    String? color,
    bool? isDefault,
  }) {
    return Wallet(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}
