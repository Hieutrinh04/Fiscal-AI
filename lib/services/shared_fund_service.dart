import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shared_fund.dart';

class SharedFundService {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// ================= CREATE FUND =================
  Future<SharedFund> createFund({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    List<String> memberIds = const [],
  }) async {
    /// Tạo quỹ
    final fundData = await _client.from('shared_funds').insert({
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'creator_id': _userId,
      'deadline': deadline?.toIso8601String(),
    }).select().single();

    final fundId = fundData['id'];

    /// Thêm creator làm admin
    await _client.from('fund_members').insert({
      'fund_id': fundId,
      'user_id': _userId,
      'role': 'admin',
    });

    /// Gửi lời mời cho các thành viên khác (không thêm thẳng)
    for (final memberId in memberIds) {
      if (memberId == _userId) continue;
      try {
        await _client.from('fund_invitations').insert({
          'fund_id': fundId,
          'invited_by': _userId,
          'invited_user_id': memberId,
          'status': 'pending',
        });

        /// Tạo thông báo cho người được mời
        await _client.from('notifications').insert({
          'user_id': memberId,
          'title': 'Lời mời tham gia quỹ',
          'body': 'Bạn được mời tham gia quỹ "$name".',
          'type': 'fund_invite',
          'is_read': false,
        });
      } catch (e) {
        print('[FUND] ERROR inviting member $memberId: $e');
      }
    }

    return SharedFund.fromJson(fundData);
  }

  /// ================= GET PENDING INVITATIONS (cho tôi) =================
  Future<List<FundInvitation>> getMyInvitations() async {
    try {
      print('[FUND] getMyInvitations START, userId=$_userId');
      final data = await _client
          .from('fund_invitations')
          .select('*, shared_funds(name)')
          .eq('invited_user_id', _userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      print('[FUND] getMyInvitations raw: $data');
      return (data as List).map((e) => FundInvitation.fromJson(e)).toList();
    } catch (e, st) {
      print('[FUND] getMyInvitations ERROR: $e');
      print('[FUND] STACK: $st');
      rethrow;
    }
  }

  /// ================= ACCEPT INVITATION =================
  Future<void> acceptInvitation(String invitationId, String fundId) async {
    /// Cập nhật trạng thái lời mời
    await _client
        .from('fund_invitations')
        .update({'status': 'accepted'})
        .eq('id', invitationId);

    /// Thêm vào fund_members
    await _client.from('fund_members').insert({
      'fund_id': fundId,
      'user_id': _userId,
      'role': 'member',
    });
  }

  /// ================= DECLINE INVITATION =================
  Future<void> declineInvitation(String invitationId) async {
    await _client
        .from('fund_invitations')
        .update({'status': 'declined'})
        .eq('id', invitationId);
  }

  /// ================= INVITE MEMBER (from fund detail) =================
  Future<void> inviteMember(String fundId, String userId, String fundName) async {
    await _client.from('fund_invitations').insert({
      'fund_id': fundId,
      'invited_by': _userId,
      'invited_user_id': userId,
      'status': 'pending',
    });

    await _client.from('notifications').insert({
      'user_id': userId,
      'title': 'Lời mời tham gia quỹ',
      'body': 'Bạn được mời tham gia quỹ "$fundName".',
      'type': 'fund_invite',
      'is_read': false,
    });
  }

  /// ================= GET MY FUNDS =================
  Future<List<SharedFund>> getMyFunds() async {
    print('[FUND] ====== getMyFunds START ======');
    print('[FUND] userId=$_userId');

    try {
      /// STEP 1: lấy fund_ids từ fund_members
      final memberData = await _client
          .from('fund_members')
          .select('fund_id')
          .eq('user_id', _userId);
      print('[FUND] STEP1 fund_members raw: $memberData');

      final fundIds = (memberData as List).map((e) => e['fund_id'] as String).toList();
      print('[FUND] STEP1 fundIds: $fundIds (count=${fundIds.length})');

      if (fundIds.isEmpty) {
        print('[FUND] fundIds EMPTY → return []');
        return [];
      }

      /// STEP 2: lấy shared_funds
      final data = await _client
          .from('shared_funds')
          .select('''
            *,
            creator_profile:profiles!shared_funds_creator_id_profiles_fkey(full_name),
            fund_members(
              *,
              profile:profiles!fund_members_user_id_profiles_fkey(full_name, email, avatar_url)
            )
          ''')
          .inFilter('id', fundIds)
          .order('created_at', ascending: false);
      print('[FUND] STEP2 shared_funds count: ${(data as List).length}');

      return data.map((e) => SharedFund.fromJson(e)).toList();
    } catch (e, st) {
      print('[FUND] ERROR: $e');
      print('[FUND] STACK: $st');
      rethrow;
    }
  }

  /// ================= GET FUND DETAIL =================
  Future<SharedFund?> getFundDetail(String fundId) async {
    final data = await _client
        .from('shared_funds')
        .select('''
          *,
          creator_profile:profiles!shared_funds_creator_id_profiles_fkey(full_name),
          fund_members(
            *,
            profile:profiles!fund_members_user_id_profiles_fkey(full_name, email, avatar_url)
          )
        ''')
        .eq('id', fundId)
        .maybeSingle();

    if (data == null) return null;
    return SharedFund.fromJson(data);
  }

  /// ================= CONTRIBUTE TO FUND (+ trừ ví) =================
  Future<FundTransaction> contribute({
    required String fundId,
    required double amount,
    required String walletId,
    String? note,
  }) async {
    /// Trừ tiền ví
    final wallet = await _client
        .from('wallets')
        .select('balance')
        .eq('id', walletId)
        .single();
    final currentBalance = wallet['balance'] as int;
    final newBalance = currentBalance - amount.toInt();
    if (newBalance < 0) throw Exception('Số dư ví không đủ');

    await _client
        .from('wallets')
        .update({'balance': newBalance})
        .eq('id', walletId);

    /// Tạo giao dịch góp quỹ
    final data = await _client.from('fund_transactions').insert({
      'fund_id': fundId,
      'user_id': _userId,
      'amount': amount,
      'note': note,
    }).select().single();

    return FundTransaction.fromJson(data);
  }

  /// ================= GET FUND TRANSACTIONS =================
  Future<List<FundTransaction>> getFundTransactions(String fundId) async {
    final data = await _client
        .from('fund_transactions')
        .select('''
          *,
          profile:profiles!fund_transactions_user_id_profiles_fkey(full_name)
        ''')
        .eq('fund_id', fundId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => FundTransaction.fromJson(e)).toList();
  }

  /// ================= ADD MEMBER TO FUND =================
  Future<void> addMember(String fundId, String userId) async {
    await _client.from('fund_members').insert({
      'fund_id': fundId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// ================= REMOVE MEMBER =================
  Future<void> removeMember(String fundId, String userId) async {
    await _client
        .from('fund_members')
        .delete()
        .eq('fund_id', fundId)
        .eq('user_id', userId);
  }

  /// ================= UPDATE FUND =================
  Future<void> updateFund(String fundId, Map<String, dynamic> updates) async {
    await _client.from('shared_funds').update(updates).eq('id', fundId);
  }

  /// ================= DELETE FUND =================
  Future<void> deleteFund(String fundId) async {
    await _client.from('shared_funds').delete().eq('id', fundId);
  }

  /// ================= CREATE REMINDER =================
  Future<FundReminder> createReminder({
    required String fundId,
    required String frequency,
    required double amount,
    int? dayOfWeek,
    int? dayOfMonth,
  }) async {
    final data = await _client.from('fund_reminders').upsert({
      'fund_id': fundId,
      'user_id': _userId,
      'frequency': frequency,
      'amount': amount,
      'day_of_week': dayOfWeek,
      'day_of_month': dayOfMonth,
      'is_active': true,
    }).select().single();

    return FundReminder.fromJson(data);
  }

  /// ================= GET MY REMINDERS =================
  Future<List<FundReminder>> getMyReminders() async {
    final data = await _client
        .from('fund_reminders')
        .select('*, shared_funds(name)')
        .eq('user_id', _userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List).map((e) => FundReminder.fromJson(e)).toList();
  }

  /// ================= GET FUND REMINDER =================
  Future<FundReminder?> getFundReminder(String fundId) async {
    final data = await _client
        .from('fund_reminders')
        .select('*, shared_funds(name)')
        .eq('fund_id', fundId)
        .eq('user_id', _userId)
        .maybeSingle();

    if (data == null) return null;
    return FundReminder.fromJson(data);
  }

  /// ================= TOGGLE REMINDER =================
  Future<void> toggleReminder(String reminderId, bool isActive) async {
    await _client
        .from('fund_reminders')
        .update({'is_active': isActive})
        .eq('id', reminderId);
  }

  /// ================= DELETE REMINDER =================
  Future<void> deleteReminder(String reminderId) async {
    await _client.from('fund_reminders').delete().eq('id', reminderId);
  }
}
