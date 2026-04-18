import 'category.dart';

class Budget {
  final String id;
  final String userId;
  final String? categoryId;
  final int amount;
  final int spent;
  final int month;
  final int year;
  final DateTime createdAt;

  // Quan hệ
  final Category? category;

  Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    this.spent = 0,
    required this.month,
    required this.year,
    required this.createdAt,
    this.category,
  });

  double get progress => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
  int get remaining => amount - spent;
  bool get isOverBudget => spent > amount;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: json['amount'] as int,
      spent: json['spent'] as int? ?? 0,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['categories'] != null
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'spent': spent,
      'month': month,
      'year': year,
    };
  }

  Budget copyWith({
    String? categoryId,
    int? amount,
    int? spent,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id,
      userId: userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt,
      category: category,
    );
  }
}
