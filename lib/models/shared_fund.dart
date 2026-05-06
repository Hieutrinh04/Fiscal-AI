class SharedFund {
  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final String creatorId;
  final DateTime? deadline;
  final String status; // active, completed, cancelled
  final DateTime createdAt;

  /// Join data
  final String? creatorName;
  final List<FundMember> members;

  SharedFund({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.creatorId,
    this.deadline,
    required this.status,
    required this.createdAt,
    this.creatorName,
    this.members = const [],
  });

  factory SharedFund.fromJson(Map<String, dynamic> json) {
    return SharedFund(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      currentAmount: (json['current_amount'] ?? 0).toDouble(),
      creatorId: json['creator_id'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      creatorName: json['creator_profile']?['full_name'],
      members: (json['fund_members'] as List?)
              ?.map((m) => FundMember.fromJson(m))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'target_amount': targetAmount,
        'creator_id': creatorId,
        'deadline': deadline?.toIso8601String(),
      };

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  bool get isCompleted => status == 'completed' || currentAmount >= targetAmount;
  bool get isActive => status == 'active';
  int get memberCount => members.length;
}

class FundMember {
  final String id;
  final String fundId;
  final String userId;
  final double contributedAmount;
  final String role; // admin, member
  final DateTime joinedAt;

  /// Join data
  final String? userName;
  final String? userEmail;
  final String? userAvatar;

  FundMember({
    required this.id,
    required this.fundId,
    required this.userId,
    required this.contributedAmount,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userEmail,
    this.userAvatar,
  });

  factory FundMember.fromJson(Map<String, dynamic> json) {
    return FundMember(
      id: json['id'],
      fundId: json['fund_id'],
      userId: json['user_id'],
      contributedAmount: (json['contributed_amount'] ?? 0).toDouble(),
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      userName: json['profile']?['full_name'],
      userEmail: json['profile']?['email'],
      userAvatar: json['profile']?['avatar_url'],
    );
  }

  bool get isAdmin => role == 'admin';
}

class FundTransaction {
  final String id;
  final String fundId;
  final String userId;
  final double amount;
  final String? note;
  final DateTime createdAt;

  /// Join data
  final String? userName;

  FundTransaction({
    required this.id,
    required this.fundId,
    required this.userId,
    required this.amount,
    this.note,
    required this.createdAt,
    this.userName,
  });

  factory FundTransaction.fromJson(Map<String, dynamic> json) {
    return FundTransaction(
      id: json['id'],
      fundId: json['fund_id'],
      userId: json['user_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['profile']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'fund_id': fundId,
        'user_id': userId,
        'amount': amount,
        'note': note,
      };
}

class FundInvitation {
  final String id;
  final String fundId;
  final String invitedBy;
  final String invitedUserId;
  final String status; // pending, accepted, declined
  final DateTime createdAt;

  /// Join data
  final String? fundName;
  final String? inviterName;

  FundInvitation({
    required this.id,
    required this.fundId,
    required this.invitedBy,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
    this.fundName,
    this.inviterName,
  });

  factory FundInvitation.fromJson(Map<String, dynamic> json) {
    return FundInvitation(
      id: json['id'],
      fundId: json['fund_id'],
      invitedBy: json['invited_by'],
      invitedUserId: json['invited_user_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      fundName: json['shared_funds']?['name'],
      inviterName: json['inviter_profile']?['full_name'],
    );
  }

  bool get isPending => status == 'pending';
}

class FundReminder {
  final String id;
  final String fundId;
  final String userId;
  final String frequency; // weekly, monthly
  final double amount;
  final int? dayOfWeek;   // 1-7 (T2-CN)
  final int? dayOfMonth;  // 1-28
  final bool isActive;
  final DateTime? nextRemindAt;
  final DateTime createdAt;

  /// Join data
  final String? fundName;

  FundReminder({
    required this.id,
    required this.fundId,
    required this.userId,
    required this.frequency,
    required this.amount,
    this.dayOfWeek,
    this.dayOfMonth,
    this.isActive = true,
    this.nextRemindAt,
    required this.createdAt,
    this.fundName,
  });

  factory FundReminder.fromJson(Map<String, dynamic> json) {
    return FundReminder(
      id: json['id'],
      fundId: json['fund_id'],
      userId: json['user_id'],
      frequency: json['frequency'],
      amount: (json['amount'] ?? 0).toDouble(),
      dayOfWeek: json['day_of_week'],
      dayOfMonth: json['day_of_month'],
      isActive: json['is_active'] ?? true,
      nextRemindAt: json['next_remind_at'] != null
          ? DateTime.parse(json['next_remind_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      fundName: json['shared_funds']?['name'],
    );
  }

  String get frequencyLabel => frequency == 'weekly' ? 'Hàng tuần' : 'Hàng tháng';

  String get scheduleLabel {
    if (frequency == 'weekly' && dayOfWeek != null) {
      const days = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
      return days[dayOfWeek!.clamp(1, 7)];
    }
    if (frequency == 'monthly' && dayOfMonth != null) {
      return 'Ngày $dayOfMonth';
    }
    return '';
  }
}
