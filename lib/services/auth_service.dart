import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final _client = Supabase.instance.client;

  /// ================= SIGN UP =================
  Future<User?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
      },
    );

    final user = response.user;

    /// 👉 tạo profile luôn
    if (user != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': email,
        'full_name': fullName ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return user;
  }

  /// ================= SIGN IN =================
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.user;
  }

  /// ================= FORGOT PASSWORD =================
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb
          ? 'http://localhost:3000'
          : 'com.example.wallet://login-callback',
    );
  }

  /// ================= GOOGLE SIGN IN (Supabase OAuth) =================
  ///
  /// Web: dùng redirectMode (chuyển hẳn sang trang Google rồi quay lại)
  /// Mobile: dùng deep link để app nhận callback
  ///
  /// Session được xử lý qua onAuthStateChange listener.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      /// Web: dùng redirect mode – ổn định hơn popup (không bị chặn)
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null, // Supabase dùng Site URL từ dashboard
      );
    } else {
      /// Mobile: cần deep link
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.wallet://login-callback',
      );
    }
  }

  /// ================= ENSURE PROFILE (gọi từ listener) =================
  Future<void> ensureProfile(User user) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            '',
        'avatar_url': user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'] ??
            '',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// ================= UPDATE PASSWORD (after reset) =================
  Future<User?> updatePassword({required String newPassword}) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response.user;
  }

  /// ================= SIGN OUT =================
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// ================= GET PROFILE =================
  Future<Profile?> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return Profile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// ================= UPDATE PROFILE =================
  Future<Profile?> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? currency,
    String? language,
  }) async {
    final updateData = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (currency != null) 'currency': currency,
      if (language != null) 'language': language,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final data = await _client
        .from('profiles')
        .update(updateData)
        .eq('id', userId)
        .select()
        .maybeSingle();

    if (data == null) return null;

    return Profile.fromJson(data);
  }

  /// ================= HELPERS =================
  User? get currentUser => _client.auth.currentUser;

  String? get userId => currentUser?.id;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}