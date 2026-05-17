import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final _client = Supabase.instance.client;

  /// Deep link dùng cho cả forgot-password và OAuth callback.
  /// Phải khớp với `<data android:scheme=... android:host=... />` trong
  /// AndroidManifest.xml và được whitelist trong Supabase Dashboard →
  /// Authentication → URL Configuration → Redirect URLs.
  static const String _deepLinkRedirect = 'com.example.wallet://login-callback';

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
  /// Gửi email reset password với deep link redirect về app.
  /// Email Supabase sẽ dẫn user tới `com.example.wallet://login-callback?code=xxx`,
  /// Android mở app qua intent-filter và supabase_flutter exchange code → fire
  /// `AuthChangeEvent.passwordRecovery`.
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _deepLinkRedirect,
    );
  }

  /// ================= GOOGLE SIGN IN (Supabase OAuth) =================
  ///
  /// Mobile flow:
  /// 1. Mở Custom Tab (Chrome trong app) tới trang Google login.
  /// 2. Sau khi user đồng ý, Google redirect về Supabase, Supabase redirect
  ///    về `com.example.wallet://login-callback?code=xxx`.
  /// 3. Android intent-filter (AndroidManifest.xml) bắt URL → mở lại app.
  /// 4. supabase_flutter exchange code → fire `AuthChangeEvent.signedIn`.
  ///
  /// Yêu cầu: URL `com.example.wallet://login-callback` phải được whitelist
  /// trong Supabase Dashboard → Authentication → URL Configuration →
  /// Redirect URLs.
  ///
  /// Trả về `true` nếu URL OAuth đã được mở thành công.
  ///
  /// Dùng `LaunchMode.platformDefault` (Custom Tabs trên Android) — tab này
  /// TỰ ĐÓNG khi gặp redirect tới custom scheme `com.example.wallet://...`,
  /// không để lại trang 404 trong Chrome như khi dùng `externalApplication`.
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _deepLinkRedirect,
      authScreenLaunchMode: LaunchMode.platformDefault,
      // 🔥 Bắt buộc Google hiện màn chọn tài khoản mỗi lần — tránh tự động
      // đăng nhập với account đã lưu trong Chrome.
      queryParams: const {'prompt': 'select_account'},
    );
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