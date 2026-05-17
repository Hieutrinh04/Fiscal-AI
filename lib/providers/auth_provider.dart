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

  /// ================= RESET PASSWORD =================
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.resetPassword(email: email);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ================= GOOGLE SIGN IN (Supabase OAuth) =================
  ///
  /// Mở URL OAuth – session được xử lý qua onAuthStateChange listener.
  /// _isLoading được reset NGAY sau khi launch xong, để user không bị kẹt
  /// nút disabled nếu họ huỷ hoặc quay lại app mà chưa đăng nhập.
  Future<void> signInWithGoogle() async {
    _error = null;
    _setLoading(true);

    try {
      debugPrint('[AUTH] Gọi signInWithGoogle...');
      final launched = await _authService.signInWithGoogle();
      debugPrint('[AUTH] signInWithGoogle launched=$launched');
      if (!launched) {
        _error = 'Không thể mở trình duyệt để đăng nhập Google';
      }
    } catch (e) {
      debugPrint('[AUTH] signInWithGoogle LỖI: $e');
      _error = e.toString();
    } finally {
      /// 🔥 Reset loading ngay khi browser đã mở (hoặc lỗi) — không chờ listener
      _setLoading(false);
    }
  }

  /// ================= HANDLE AUTH STATE CHANGE =================
  /// Gọi từ onAuthStateChange listener trong main.dart
  Future<void> handleAuthStateChange(AuthChangeEvent event, Session? session) async {
    debugPrint('[AUTH] event=$event, session=${session != null ? "có" : "không"}');

    if (event == AuthChangeEvent.signedIn && session != null) {
      _user = session.user;
      debugPrint('[AUTH] signedIn – user=${_user?.email}');
      await _authService.ensureProfile(_user!);
      await loadProfile();
      _error = null;
      _isLoading = false;
      notifyListeners();
    } else if (event == AuthChangeEvent.signedOut) {
      _user = null;
      _profile = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } else if (event == AuthChangeEvent.passwordRecovery) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ================= UPDATE PASSWORD (after reset email) =================
  Future<bool> updatePassword({required String newPassword}) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.updatePassword(newPassword: newPassword);
      _user = Supabase.instance.client.auth.currentUser;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
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