enum TransactionType { income, expense, transfer }

extension TransactionTypeExt on TransactionType {
  String get value => name;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}

class Category {
  final String id;
  final String? userId;
  final String name;
  final String icon;
  final String color;
  final TransactionType type;
  final bool isSystem;
  final DateTime createdAt;

  Category({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.type = TransactionType.expense,
    this.isSystem = false,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'];
    final createdAtValue = json['created_at'];
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '💰',
      color: json['color'] as String? ?? '#3B82F6',
      type: typeValue is String ? TransactionTypeExt.fromString(typeValue) : TransactionType.expense,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: createdAtValue is String ? DateTime.parse(createdAtValue) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.value,
      'is_system': isSystem,
    };
  }

  Category copyWith({
    String? name,
    String? icon,
    String? color,
    TransactionType? type,
  }) {
    return Category(
      id: id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isSystem: isSystem,
      createdAt: createdAt,
    );
  }
}
