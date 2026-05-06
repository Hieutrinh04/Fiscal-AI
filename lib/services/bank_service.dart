import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_account.dart';
import '../utils/env.dart';

class BankService {
  final _client = Supabase.instance.client;

  /// ================= SEPAY CONFIG =================
  /// Đăng ký tại: https://my.sepay.vn
  /// Lấy API key tại: https://my.sepay.vn/userapi
  static const String _sepayBaseUrl = 'https://my.sepay.vn/userapi';
  String? _sepayApiKey;

  void setSepayApiKey(String key) => _sepayApiKey = key;

  /// ================= HELPER: GỌI SEPAY QUA PROXY (tránh CORS trên web) =================
  Future<Map<String, dynamic>> _callSepay({
    required String endpoint,
    Map<String, dynamic>? params,
  }) async {
    if (_sepayApiKey == null || _sepayApiKey!.isEmpty) {
      throw Exception('SePay API key chưa được cấu hình');
    }

    http.Response response;

    if (kIsWeb) {
      /// Trên Web → gọi qua Supabase Edge Function proxy (tránh CORS)
      debugPrint('[BANK] Using proxy: ${Env.sepayProxyUrl}');
      response = await http.post(
        Uri.parse(Env.sepayProxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? Env.supabaseAnonKey}',
          'apikey': Env.supabaseAnonKey,
        },
        body: jsonEncode({
          'endpoint': endpoint,
          'params': params,
          'apiKey': _sepayApiKey,
        }),
      );
    } else {
      /// Trên Mobile/Desktop → gọi trực tiếp SePay
      final uri = Uri.parse('$_sepayBaseUrl/$endpoint').replace(
        queryParameters: params?.map((k, v) => MapEntry(k, v.toString())),
      );
      debugPrint('[BANK] Direct call: $uri');
      response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_sepayApiKey',
          'Content-Type': 'application/json',
        },
      );
    }

    debugPrint('[BANK] Response status: ${response.statusCode}');
    if (response.statusCode == 401) {
      if (kIsWeb) {
        throw Exception('Proxy xác thực thất bại (401) — tắt JWT Verification trên Supabase Edge Function hoặc kiểm tra API key');
      }
      throw Exception('SePay API key không hợp lệ hoặc hết hạn (401)');
    }
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// ================= FETCH SEPAY BANK ACCOUNTS =================
  Future<List<Map<String, dynamic>>> fetchSepayBankAccounts() async {
    try {
      final data = await _callSepay(endpoint: 'bankaccounts/list');
      if (data['status'] == 200 && data['bankaccounts'] != null) {
        return List<Map<String, dynamic>>.from(data['bankaccounts']);
      }
      final msg = data['messages']?.toString() ?? data['error']?.toString() ?? 'Lỗi không xác định';
      throw Exception('SePay API lỗi: $msg');
    } catch (e) {
      debugPrint('[BANK] Fetch SePay accounts error: $e');
      rethrow;
    }
  }

  /// ================= VERIFY BANK ACCOUNT (SePay) =================
  /// Xác minh tài khoản bằng cách so khớp với danh sách trên SePay
  Future<String?> verifyBankAccount({
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      final accounts = await fetchSepayBankAccounts();
      debugPrint('[BANK] SePay accounts count: ${accounts.length}');

      for (final acc in accounts) {
        debugPrint('[BANK] SePay account: ${acc['account_number']} - ${acc['account_holder_name']}');
        if (acc['account_number']?.toString() == accountNumber) {
          return acc['account_holder_name']?.toString();
        }
      }

      debugPrint('[BANK] Account $accountNumber not found in SePay list');
      throw Exception('Tài khoản $accountNumber không tìm thấy trong danh sách SePay');
    } catch (e) {
      debugPrint('[BANK] Verify error: $e');
      throw Exception('Lỗi khi xác minh tài khoản ngân hàng: $e');
    }
  }

  /// ================= LINK BANK ACCOUNT =================
  Future<BankAccount> linkBankAccount({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    bool isVerified = false,
    String? walletId,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client.from('bank_accounts').insert({
      'user_id': userId,
      'bank_name': bankName,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'account_name': accountName,
      'is_verified': isVerified,
      'wallet_id': walletId,
    }).select().single();

    return BankAccount.fromJson(data);
  }

  /// ================= GET BANK ACCOUNTS =================
  Future<List<BankAccount>> getBankAccounts() async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('bank_accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => BankAccount.fromJson(e)).toList();
  }

  /// ================= DELETE BANK ACCOUNT =================
  Future<void> deleteBankAccount(String id) async {
    await _client.from('bank_accounts').delete().eq('id', id);
  }

  /// ================= UPDATE WALLET LINK =================
  Future<void> updateWalletLink(String bankAccountId, String? walletId) async {
    await _client
        .from('bank_accounts')
        .update({'wallet_id': walletId})
        .eq('id', bankAccountId);
  }

  /// ================= FETCH SEPAY TRANSACTIONS =================
  Future<List<Map<String, dynamic>>> fetchSepayTransactions({
    required String accountNumber,
    int limit = 20,
    String? transactionDateMin,
    String? transactionDateMax,
  }) async {
    try {
      final params = <String, dynamic>{
        'account_number': accountNumber,
        'limit': limit,
      };
      if (transactionDateMin != null) params['transaction_date_min'] = transactionDateMin;
      if (transactionDateMax != null) params['transaction_date_max'] = transactionDateMax;

      final data = await _callSepay(
        endpoint: 'transactions/list',
        params: params,
      );

      if (data['status'] == 200 && data['transactions'] != null) {
        return List<Map<String, dynamic>>.from(data['transactions']);
      }
      return [];
    } catch (e) {
      debugPrint('[BANK] Fetch transactions error: $e');
      return [];
    }
  }

  /// ================= GET SEPAY ACCOUNT BALANCE =================
  /// Lấy số dư tích lũy (accumulated) từ SePay
  Future<Map<String, dynamic>?> getSepayAccountInfo(String accountNumber) async {
    try {
      final accounts = await fetchSepayBankAccounts();
      for (final acc in accounts) {
        if (acc['account_number']?.toString() == accountNumber) {
          return acc;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[BANK] Get account info error: $e');
      return null;
    }
  }

  /// ================= SYNC SEPAY TRANSACTIONS TO DATABASE =================
  /// Đồng bộ giao dịch từ SePay vào database local
  /// Trả về số lượng giao dịch đã đồng bộ
  Future<int> syncSepayTransactionsToDatabase({
    required String accountNumber,
    required String walletId,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      
      // Lấy danh sách giao dịch từ SePay
      final sepayTransactions = await fetchSepayTransactions(
        accountNumber: accountNumber,
        limit: 100,
      );

      if (sepayTransactions.isEmpty) {
        debugPrint('[BANK] No SePay transactions to sync');
        return 0;
      }

      int syncedCount = 0;
      int balanceDelta = 0;

      for (final tx in sepayTransactions) {
        final amountIn = double.tryParse(tx['amount_in']?.toString() ?? '0') ?? 0.0;
        final amountOut = double.tryParse(tx['amount_out']?.toString() ?? '0') ?? 0.0;
        final isIncome = amountIn > 0;
        final amount = isIncome ? amountIn : amountOut;
        
        // Bỏ qua giao dịch không có số tiền
        if (amount <= 0) continue;

        final transactionDate = tx['transaction_date'];
        final content = tx['transaction_content'] ?? '';
        final refNumber = tx['reference_number'] ?? '';

        // Kiểm tra xem giao dịch đã tồn tại trong database chưa
        // Sử dụng reference_number hoặc content + date làm unique key
        final existing = await _client
            .from('transactions')
            .select()
            .eq('user_id', userId)
            .eq('wallet_id', walletId)
            .eq('note', content.isNotEmpty ? content : 'Giao dịch #$refNumber')
            .gte('date', transactionDate)
            .limit(1);

        if (existing.isNotEmpty) {
          debugPrint('[BANK] Transaction already exists, skipping');
          continue;
        }

        // Chèn giao dịch mới vào database
        await _client.from('transactions').insert({
          'user_id': userId,
          'wallet_id': walletId,
          'type': isIncome ? 'income' : 'expense',
          'amount': amount.toInt(),
          'note': content.isNotEmpty ? content : 'Giao dịch #$refNumber',
          'date': transactionDate,
          'created_at': DateTime.now().toIso8601String(),
        });

        syncedCount++;
        // Tích lũy thay đổi số dư
        balanceDelta += isIncome ? amount.toInt() : -amount.toInt();
        debugPrint('[BANK] Synced transaction: ${content.isNotEmpty ? content : 'Giao dịch #$refNumber'} - $amount');
      }

      // Cập nhật số dư ví nếu có giao dịch mới
      if (syncedCount > 0 && balanceDelta != 0) {
        final walletData = await _client
            .from('wallets')
            .select('balance')
            .eq('id', walletId)
            .single();
        final currentBalance = walletData['balance'] as int? ?? 0;
        final newBalance = currentBalance + balanceDelta;
        await _client
            .from('wallets')
            .update({'balance': newBalance})
            .eq('id', walletId);
        debugPrint('[BANK] Updated wallet balance: $currentBalance → $newBalance (delta: $balanceDelta)');
      }

      debugPrint('[BANK] Synced $syncedCount transactions to database');
      return syncedCount;
    } catch (e) {
      debugPrint('[BANK] Sync transactions error: $e');
      rethrow;
    }
  }
}
