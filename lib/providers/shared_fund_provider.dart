import 'package:flutter/material.dart';
import '../models/shared_fund.dart';
import '../services/shared_fund_service.dart';

class SharedFundProvider extends ChangeNotifier {
  final SharedFundService _service = SharedFundService();

  List<SharedFund> _funds = [];
  SharedFund? _selectedFund;
  List<FundTransaction> _transactions = [];
  List<FundInvitation> _invitations = [];
  FundReminder? _currentReminder;
  List<FundReminder> _reminders = [];
  bool _isLoading = false;
  String? _error;

  List<SharedFund> get funds => _funds;
  SharedFund? get selectedFund => _selectedFund;
  List<FundTransaction> get transactions => _transactions;
  List<FundInvitation> get invitations => _invitations;
  int get pendingInvitationCount => _invitations.length;
  FundReminder? get currentReminder => _currentReminder;
  List<FundReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SharedFund> get activeFunds =>
      _funds.where((f) => f.isActive).toList();

  /// ================= LOAD FUNDS =================
  Future<void> loadFunds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _funds = await _service.getMyFunds();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================= CREATE FUND =================
  Future<SharedFund?> createFund({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    List<String> memberIds = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fund = await _service.createFund(
        name: name,
        description: description,
        targetAmount: targetAmount,
        deadline: deadline,
        memberIds: memberIds,
      );
      await loadFunds();
      return fund;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// ================= LOAD FUND DETAIL =================
  Future<void> loadFundDetail(String fundId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedFund = await _service.getFundDetail(fundId);
      _transactions = await _service.getFundTransactions(fundId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================= CONTRIBUTE =================
  Future<bool> contribute({
    required String fundId,
    required double amount,
    required String walletId,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.contribute(
        fundId: fundId,
        amount: amount,
        walletId: walletId,
        note: note,
      );
      await loadFundDetail(fundId);
      await loadFunds();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ================= INVITE MEMBER =================
  Future<bool> inviteMember(String fundId, String userId, String fundName) async {
    try {
      await _service.inviteMember(fundId, userId, fundName);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= LOAD INVITATIONS =================
  Future<void> loadInvitations() async {
    try {
      _invitations = await _service.getMyInvitations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// ================= ACCEPT INVITATION =================
  Future<bool> acceptInvitation(String invitationId, String fundId) async {
    try {
      await _service.acceptInvitation(invitationId, fundId);
      _invitations.removeWhere((i) => i.id == invitationId);
      notifyListeners();
      await loadFunds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= DECLINE INVITATION =================
  Future<bool> declineInvitation(String invitationId) async {
    try {
      await _service.declineInvitation(invitationId);
      _invitations.removeWhere((i) => i.id == invitationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= REMOVE MEMBER =================
  Future<bool> removeMember(String fundId, String userId) async {
    try {
      await _service.removeMember(fundId, userId);
      await loadFundDetail(fundId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= DELETE FUND =================
  Future<bool> deleteFund(String fundId) async {
    try {
      await _service.deleteFund(fundId);
      _funds.removeWhere((f) => f.id == fundId);
      _selectedFund = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= LOAD FUND REMINDER =================
  Future<void> loadFundReminder(String fundId) async {
    try {
      _currentReminder = await _service.getFundReminder(fundId);
      notifyListeners();
    } catch (e) {
      _currentReminder = null;
    }
  }

  /// ================= LOAD ALL REMINDERS =================
  Future<void> loadReminders() async {
    try {
      _reminders = await _service.getMyReminders();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// ================= CREATE/UPDATE REMINDER =================
  Future<bool> setReminder({
    required String fundId,
    required String frequency,
    required double amount,
    int? dayOfWeek,
    int? dayOfMonth,
  }) async {
    try {
      _currentReminder = await _service.createReminder(
        fundId: fundId,
        frequency: frequency,
        amount: amount,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= DELETE REMINDER =================
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _service.deleteReminder(reminderId);
      _currentReminder = null;
      _reminders.removeWhere((r) => r.id == reminderId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
