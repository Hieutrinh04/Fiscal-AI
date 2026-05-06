import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/bank_account.dart';
import '../services/bank_service.dart';
import '../utils/env.dart';

class BankProvider extends ChangeNotifier {
  final BankService _service = BankService()..setSepayApiKey(Env.sepayApiKey);

  List<BankAccount> _accounts = [];
  bool _isLoading = false;
  String? _error;

  List<BankAccount> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ================= LOAD ACCOUNTS =================
  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _service.getBankAccounts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================= VERIFY & LINK =================
  Future<BankAccount?> verifyAndLink({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    String? walletId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      /// Bước 1: Xác minh qua SePay
      final accountName = await _service.verifyBankAccount(
        bankCode: bankCode,
        accountNumber: accountNumber,
      );

      if (accountName == null) {
        _error = 'Tài khoản không có trong danh sách SePay.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      /// Bước 2: Lưu vào database
      final account = await _service.linkBankAccount(
        bankName: bankName,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountName: accountName,
        isVerified: true,
        walletId: walletId,
      );

      _accounts.insert(0, account);
      _isLoading = false;
      notifyListeners();
      return account;
    } catch (e) {
      /// Hiển thị lỗi thực sự (CORS, API key sai, không tìm thấy TK...)
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// ================= LINK WITHOUT VERIFY =================
  /// Liên kết thủ công (không qua SePay)
  Future<BankAccount?> linkManually({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    String? walletId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final account = await _service.linkBankAccount(
        bankName: bankName,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountName: accountName,
        isVerified: false,
        walletId: walletId,
      );

      _accounts.insert(0, account);
      _isLoading = false;
      notifyListeners();
      return account;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// ================= DELETE =================
  Future<void> deleteAccount(String id) async {
    try {
      await _service.deleteBankAccount(id);
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// ================= FETCH BANK TRANSACTIONS =================
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> get transactions => _transactions;

  Future<void> fetchTransactions(String accountNumber, {int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _service.fetchSepayTransactions(
        accountNumber: accountNumber,
        limit: limit,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================= GET ACCOUNT INFO (BALANCE) =================
  Map<String, dynamic>? _sepayAccountInfo;
  Map<String, dynamic>? get sepayAccountInfo => _sepayAccountInfo;

  Future<void> fetchAccountInfo(String accountNumber) async {
    try {
      _sepayAccountInfo = await _service.getSepayAccountInfo(accountNumber);
      notifyListeners();
    } catch (e) {
      debugPrint('[BANK] fetchAccountInfo error: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// ================= UPDATE WALLET LINK =================
  Future<void> updateWalletLink(String bankAccountId, String? walletId) async {
    await _service.updateWalletLink(bankAccountId, walletId);
    await loadAccounts();
    notifyListeners();
  }

  /// ================= VERIFY BANK ACCOUNT =================
  Future<String?> verifyBankAccount({
    required String bankCode,
    required String accountNumber,
  }) async {
    return await _service.verifyBankAccount(
      bankCode: bankCode,
      accountNumber: accountNumber,
    );
  }

  /// ================= AUTO SYNC ALL LINKED ACCOUNTS =================
  /// Tự động sync tất cả tài khoản ngân hàng có liên kết ví — gọi lặng lẽ ở background
  Future<int> autoSyncAll() async {
    int totalSynced = 0;
    final linked = _accounts.where((a) => a.walletId != null).toList();
    for (final account in linked) {
      try {
        final count = await _service.syncSepayTransactionsToDatabase(
          accountNumber: account.accountNumber,
          walletId: account.walletId!,
        );
        totalSynced += count;
      } catch (_) {
        // Bỏ qua lỗi từng tài khoản
      }
    }
    return totalSynced;
  }

  /// ================= SYNC TRANSACTIONS TO DATABASE =================
  Future<int> syncTransactionsToDatabase({
    required String accountNumber,
    required String walletId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final syncedCount = await _service.syncSepayTransactionsToDatabase(
        accountNumber: accountNumber,
        walletId: walletId,
      );
      _isLoading = false;
      notifyListeners();
      return syncedCount;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
