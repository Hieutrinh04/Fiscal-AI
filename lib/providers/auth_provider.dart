import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    _user = Supabase.instance.client.auth.currentUser;
    if (_user != null) loadProfile();
  }

  /// ================= SIGN UP =================
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);

    _error = null; // ✅ reset trước khi gọi API

    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      _error = null; // ✅ đảm bảo success không còn lỗi
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false); // ✅ luôn đảm bảo update UI
    }
  }

  /// ================= SIGN IN =================
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    _error = null; // ✅ reset trước

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      _user = user;

      if (_user != null) {
        await loadProfile();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ================= SIGN OUT =================
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _user = null;
      _profile = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    if (_user == null) return;

    try {
      final data = await _authService.getProfile(_user!.id);
      _profile = data;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// ================= UPDATE PROFILE =================
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
    String? language,
  }) async {
    if (_user == null) return;

    _setLoading(true);

    _error = null; // ✅ reset trước

    try {
      final data = await _authService.updateProfile(
        userId: _user!.id,
        fullName: fullName,
        phone: phone,
        currency: currency,
        language: language,
      );

      _profile = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
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