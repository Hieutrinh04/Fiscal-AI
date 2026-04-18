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