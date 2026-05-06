import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  final _client = Supabase.instance.client;
  final String _table = 'wallets';

  /// ================= GET ALL =================
  Future<List<Map<String, dynamic>>> getWallets(String userId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  /// ================= GET BY ID =================
  Future<Map<String, dynamic>?> getWalletById(String walletId) async {
    try {
      return await _client
          .from(_table)
          .select()
          .eq('id', walletId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  /// ================= CREATE =================
  Future<Map<String, dynamic>> addWallet({
    required String userId,
    required String name,
    int balance = 0,
    String? icon,
    String? color,
  }) async {
    final data = await _client.from(_table).insert({
      'user_id': userId,
      'name': name,
      'balance': balance,
      'icon': icon,
      'color': color,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();
    return data;
  }

  /// ================= UPDATE =================
  Future<void> updateWallet(
    String walletId,
    Map<String, dynamic> updates,
  ) async {
    await _client.from(_table).update({
      ...updates,
    }).eq('id', walletId);
  }

  /// ================= UPDATE BALANCE =================
  Future<void> updateBalance(String walletId, int newBalance) async {
    await _client.from(_table).update({
      'balance': newBalance,
    }).eq('id', walletId);
  }

  /// ================= TRANSFER =================
  Future<void> transfer({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
  }) async {
    final fromWallet = await getWalletById(fromWalletId);
    final toWallet = await getWalletById(toWalletId);

    if (fromWallet == null || toWallet == null) {
      throw Exception('Ví không tồn tại');
    }

    final fromBalance = (fromWallet['balance'] ?? 0) as int;
    final toBalance = (toWallet['balance'] ?? 0) as int;

    if (fromBalance < amount) {
      throw Exception('Số dư không đủ');
    }

    /// ⚠️ NOTE: Supabase không transaction → có thể lỗi race condition
    await updateBalance(fromWalletId, fromBalance - amount);
    await updateBalance(toWalletId, toBalance + amount);
  }

  /// ================= DELETE =================
  Future<void> deleteWallet(String walletId) async {
    await _client.from(_table).delete().eq('id', walletId);
  }

  /// ================= TOTAL =================
  Future<int> getTotalBalance(String userId) async {
    final wallets = await getWallets(userId);

    return wallets.fold<int>(
      0,
      (sum, w) => sum + ((w['balance'] ?? 0) as int),
    );
  }
}
