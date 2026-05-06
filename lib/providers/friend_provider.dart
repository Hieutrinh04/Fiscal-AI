import 'package:flutter/material.dart';
import '../models/friendship.dart';
import '../services/friend_service.dart';

class FriendProvider extends ChangeNotifier {
  final FriendService _service = FriendService();

  List<Friendship> _friends = [];
  List<Friendship> _pendingRequests = [];
  List<Friendship> _sentRequests = [];
  bool _isLoading = false;
  String? _error;

  List<Friendship> get friends => _friends;
  List<Friendship> get pendingRequests => _pendingRequests;
  List<Friendship> get sentRequests => _sentRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _pendingRequests.length;

  /// ================= LOAD ALL =================
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await _service.getFriends();
      _pendingRequests = await _service.getPendingRequests();
      _sentRequests = await _service.getSentRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================= SEARCH USERS =================
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    _error = null;
    try {
      return await _service.searchUsers(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// ================= SEND REQUEST =================
  Future<bool> sendRequest(String friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.sendFriendRequest(friendId);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ================= ACCEPT REQUEST =================
  Future<bool> acceptRequest(String friendshipId) async {
    try {
      await _service.acceptFriendRequest(friendshipId);
      await loadAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= REJECT REQUEST =================
  Future<bool> rejectRequest(String friendshipId) async {
    try {
      await _service.rejectFriendRequest(friendshipId);
      _pendingRequests.removeWhere((r) => r.id == friendshipId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// ================= REMOVE FRIEND =================
  Future<bool> removeFriend(String friendshipId) async {
    try {
      await _service.removeFriend(friendshipId);
      _friends.removeWhere((f) => f.id == friendshipId);
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
