import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _realtimeChannel;

  /// ================= GETTERS =================
  List<Wallet> get wallets => _wallets;
  Wallet? get selectedWallet => _selectedWallet;

  Wallet? get defaultWallet {
    try {
      return _wallets.firstWhere((w) => w.isDefault);
    } catch (_) {
      return _wallets.isNotEmpty ? _wallets.first : null;
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalBalance =>
      _wallets.fold(0, (sum, w) => sum + w.balance);

  /// Validate transfer: trả về lỗi nếu không hợp lệ, null nếu OK
  String? validateTransfer(String? fromWalletId, String? toWalletId, int amount) {
    if (_wallets.length < 2) return 'Bạn cần ít nhất 2 ví để thực hiện chuyển tiền';
    if (fromWalletId == null || toWalletId == null) return 'Vui lòng chọn tài khoản';
    if (fromWalletId == toWalletId) return 'Vui lòng chọn tài khoản khác nhau';
    if (amount <= 0) return 'Vui lòng nhập số tiền hợp lệ';
    final fromWallet = _wallets.where((w) => w.id == fromWalletId).firstOrNull;
    if (fromWallet == null) return 'Ví nguồn không tồn tại';
    if (fromWallet.balance < amount) return 'Số dư không đủ';
    return null;
  }

  /// ================= REALTIME =================
  void subscribeRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('wallets-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'wallets',
          callback: (_) => loadWallets(),
        )
        .subscribe();
  }

  void cancelRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  @override
  void dispose() {
    cancelRealtime();
    super.dispose();
  }

  /// ================= LOAD =================
  Future<void> loadWallets() async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) throw Exception('Chưa đăng nhập');

      final data = await _walletService.getWallets(user.id);

      /// 🔥 FIX: convert Map → Model
      _wallets = data.map((e) => Wallet.fromJson(e)).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ================= ADD =================
  Future<Wallet> addWallet({
    required String name,
    required String type,
    int balance = 0,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) throw Exception('Chưa đăng nhập');

      final data = await _walletService.addWallet(
        userId: user.id,
        name: name,
        balance: balance,
        icon: icon,
        color: color,
      );

      await loadWallets();

      _error = null;
      return Wallet.fromJson(data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= UPDATE =================
  Future<void> updateWallet(
    String walletId,
    Map<String, dynamic> updates,
  ) async {
    _setLoading(true);
    try {
      await _walletService.updateWallet(walletId, updates);

      await loadWallets();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= TRANSFER =================
  Future<void> transfer({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
  }) async {
    _setLoading(true);
    try {
      await _walletService.transfer(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
      );

      await loadWallets();

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= DELETE =================
  Future<void> deleteWallet(String walletId) async {
    _setLoading(true);
    try {
      await _walletService.deleteWallet(walletId);

      _wallets.removeWhere((w) => w.id == walletId);

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= SELECT =================
  void selectWallet(Wallet wallet) {
    _selectedWallet = wallet;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}