import 'category.dart';
import 'wallet.dart';

class Transaction {
  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final TransactionType type;
  final int amount;
  final String? description;
  final String? note;
  final DateTime date;
  final bool aiClassified;
  final String? aiCategorySuggestion;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Quan hệ (optional, để join)
  final Category? category;
  final Wallet? wallet;

  Transaction({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    this.note,
    required this.date,
    this.aiClassified = false,
    this.aiCategorySuggestion,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.wallet,
  });

  /// Tên hiển thị: note nếu có, nếu rỗng → tên danh mục, cuối cùng → 'Giao dịch'
  String get displayTitle {
    final n = note?.trim();
    if (n != null && n.isNotEmpty) return n;
    final catName = category?.name.trim();
    if (catName != null && catName.isNotEmpty) return catName;
    return 'Giao dịch';
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final dateValue = json['transaction_date'] ?? json['date'];
    final createdAtValue = json['created_at'];
    final updatedAtValue = json['updated_at'] ?? json['created_at'];

    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String,
      categoryId: json['category_id'] as String?,
      type: TransactionTypeExt.fromString(json['type'] as String),
      amount: json['amount'] as int,
      description: json['description'] as String?,
      note: json['note'] as String?,
      date: DateTime.parse(dateValue as String),
      aiClassified: json['ai_classified'] as bool? ?? false,
      aiCategorySuggestion: json['ai_category_suggestion'] as String?,
      createdAt: DateTime.parse(createdAtValue as String),
      updatedAt: DateTime.parse(updatedAtValue as String),
      category: json['categories'] != null
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
      wallet: json['wallets'] != null
          ? Wallet.fromJson(json['wallets'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'note': note,
      'date': date.toIso8601String(),
      'ai_classified': aiClassified,
      'ai_category_suggestion': aiCategorySuggestion,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Transaction copyWith({
    String? walletId,
    String? categoryId,
    TransactionType? type,
    int? amount,
    String? description,
    String? note,
    DateTime? date,
    bool? aiClassified,
    String? aiCategorySuggestion,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      note: note ?? this.note,
      date: date ?? this.date,
      aiClassified: aiClassified ?? this.aiClassified,
      aiCategorySuggestion: aiCategorySuggestion ?? this.aiCategorySuggestion,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      category: category,
      wallet: wallet,
    );
  }
}
