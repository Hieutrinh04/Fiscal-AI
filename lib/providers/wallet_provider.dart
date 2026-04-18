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
  Future<void> addWallet({
    required String name,
    required String type, // Vẫn nhận từ UI
    int balance = 0,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) throw Exception('Chưa đăng nhập');

      await _walletService.addWallet(
        userId: user.id,
        name: name,
        // type: type, // Không gửi lên service nữa
        balance: balance,
        icon: icon,
        color: color,
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