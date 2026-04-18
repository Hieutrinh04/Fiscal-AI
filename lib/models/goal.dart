enum GoalStatus { active, completed, cancelled }

extension GoalStatusExt on GoalStatus {
  String get value => name;

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GoalStatus.active,
    );
  }
}

class Goal {
  final String id;
  final String userId;
  final String name;
  final int targetAmount;
  final int currentAmount;
  final String icon;
  final DateTime? deadline;
  final GoalStatus status;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.icon = '🎯',
    this.deadline,
    this.status = GoalStatus.active,
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  int get remaining => targetAmount - currentAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: json['target_amount'] as int,
      currentAmount: json['current_amount'] as int? ?? 0,
      icon: json['icon'] as String? ?? '🎯',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      status: GoalStatusExt.fromString(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'icon': icon,
      'deadline': deadline?.toIso8601String(),
      'status': status.value,
    };
  }

  Goal copyWith({
    String? name,
    int? targetAmount,
    int? currentAmount,
    String? icon,
    DateTime? deadline,
    GoalStatus? status,
  }) {
    return Goal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
