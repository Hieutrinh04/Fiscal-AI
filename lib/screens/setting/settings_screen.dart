import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/ai_provider.dart';

import '../ai/ai_chat_screen.dart';
import '../wallet/wallet_screen.dart';
import '../goal/goals_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Đang tải...';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('Cài đặt',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
              ),
              _buildProfileCard(profile, userEmail),

              _buildSectionTitle('TÀI KHOẢN'),
              _buildSettingsGroup([
                _buildSettingTile(
                  icon: Icons.person_outline,
                  title: 'Thông tin cá nhân',
                  subtitle: profile != null
                      ? '${profile.fullName}, $userEmail'
                      : 'Đang tải...',
                  onTap: () => _showEditProfileModal(context, profile, userEmail),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Quản lý ví',
                  subtitle: 'Tài khoản ngân hàng, ví điện tử',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WalletScreen())),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.flag_outlined,
                  title: 'Mục tiêu tài chính',
                  subtitle: 'Theo dõi tiến độ tiết kiệm',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GoalsScreen())),
                ),
              ]),

              _buildSectionTitle('TIỆN ÍCH'),
              _buildSettingsGroup([
                _buildSettingTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Advisor',
                  subtitle: 'Tư vấn tài chính AI',
                  trailing: _buildBadge('Mới'),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AIChatScreen())),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  subtitle: _notificationEnabled ? 'Đang bật' : 'Đang tắt',
                  value: _notificationEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationEnabled = val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Chế độ tối',
                  subtitle: _darkModeEnabled ? 'Đang bật' : 'Đang tắt',
                  value: _darkModeEnabled,
                  onChanged: (val) => setState(() => _darkModeEnabled = val),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.language,
                  title: 'Ngôn ngữ',
                  subtitle: 'VN: Tiếng Việt',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LanguageScreen())),
                ),
              ]),

              _buildSectionTitle('KHÁC'),
              _buildSettingsGroup([
                _buildSettingTile(
                  icon: Icons.shield_outlined,
                  title: 'Bảo mật',
                  subtitle: 'Mật khẩu, xác thực 2 lớp',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SecurityScreen())),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: 'Trợ giúp',
                  subtitle: 'FAQ, liên hệ hỗ trợ',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HelpScreen())),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'Về ứng dụng',
                  subtitle: 'Phiên bản 1.0.0',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
              ]),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PROFILE CARD =================
  Widget _buildProfileCard(dynamic profile, String email) {
    final name = profile?.fullName ?? 'Người dùng';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditProfileModal(context, profile, email),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(email,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Row(children: [
                      Text('Tài khoản Premium ',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF3B82F6))),
                      Text('⭐', style: TextStyle(fontSize: 11)),
                    ]),
                  ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= EDIT PROFILE MODAL =================
  void _showEditProfileModal(BuildContext context, dynamic profile, String email) {
    final nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    final emailCtrl = TextEditingController(text: email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Chỉnh sửa hồ sơ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Stack(children: [
              CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                      nameCtrl.text.isNotEmpty
                          ? nameCtrl.text[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  )),
            ]),
            const SizedBox(height: 20),
            TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(
                controller: emailCtrl,
                readOnly: true,
                decoration: InputDecoration(
                    labelText: 'Email (Không thể đổi)',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().updateProfile(
                          fullName: nameCtrl.text.trim(),
                        );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Lưu thay đổi'),
                )),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  // ================= COMMON WIDGETS =================
  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 1)),
      );

  Widget _buildSettingsGroup(List<Widget> children) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      );

  Widget _buildSettingTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      Widget? trailing,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
          value: value, onChanged: onChanged, activeColor: const Color(0xFF3B82F6)),
    );
  }

  Widget _buildDivider() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1));

  Widget _buildBadge(String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10)),
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600))),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ]);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Đăng xuất',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
  }
}

  // ================= COMMON WIDGETS =================
  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1)),
  );

  Widget _buildSettingsGroup(List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF3B82F6)),
    );
  }

  Widget _buildDivider() => const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1));

  Widget _buildBadge(String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(10)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
    const SizedBox(width: 4),
    const Icon(Icons.chevron_right, color: Colors.grey),
  ]);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
  }


// ============================================================
// CÁC MÀN HÌNH PHỤ ĐƠN GIẢN (chưa có sẵn trong project)
// Thiết kế giống modal "Thông tin cá nhân"
// ============================================================

// ---- NGÔN NGỮ ----
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'vi';
  final _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final lang = _languages[i];
          final isSelected = _selected == lang['code'];
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: isSelected ? Border.all(color: const Color(0xFF3B82F6), width: 2) : null),
            child: ListTile(
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
              title: Text(lang['name']!, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF3B82F6) : null)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6)) : null,
              onTap: () => setState(() => _selected = lang['code']!),
            ),
          );
        },
      ),
    );
  }
}

// ---- BẢO MẬT ----
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Bảo mật', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.verified_user, color: Color(0xFF3B82F6)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tài khoản được bảo vệ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                Text('Mức bảo mật: Trung bình', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          _group([
            ListTile(
              leading: _iconBox(Icons.lock_outline),
              title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Cập nhật lần cuối: 30 ngày trước', style: TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {},
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
            SwitchListTile(
              secondary: _iconBox(Icons.fingerprint),
              title: const Text('Sinh trắc học', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Vân tay / Face ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _biometricEnabled, activeColor: const Color(0xFF3B82F6),
              onChanged: (v) => setState(() => _biometricEnabled = v),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
            SwitchListTile(
              secondary: _iconBox(Icons.security),
              title: const Text('Xác thực 2 lớp', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('SMS / Email OTP', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _twoFactorEnabled, activeColor: const Color(0xFF3B82F6),
              onChanged: (v) => setState(() => _twoFactorEnabled = v),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _iconBox(IconData icon) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
  );

  Widget _group(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(children: children),
  );
}

// ---- TRỢ GIÚP ----
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'Làm sao để thêm giao dịch?', 'a': 'Nhấn nút + ở thanh điều hướng, chọn loại giao dịch và điền thông tin.'},
      {'q': 'Làm sao để liên kết ngân hàng?', 'a': 'Vào Cài đặt > Quản lý ví > Thêm ví, chọn "Ngân hàng".'},
      {'q': 'Dữ liệu có an toàn không?', 'a': 'Dữ liệu được mã hóa end-to-end và lưu trữ bảo mật.'},
      {'q': 'AI Advisor hoạt động thế nào?', 'a': 'AI phân tích chi tiêu và đưa ra gợi ý tài chính cá nhân hóa.'},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Trợ giúp', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(decoration: InputDecoration(hintText: 'Tìm kiếm...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: Colors.white)),
          const SizedBox(height: 16),
          Row(children: [
            _action(Icons.email_outlined, 'Email'),
            const SizedBox(width: 12),
            _action(Icons.chat_outlined, 'Chat'),
            const SizedBox(width: 12),
            _action(Icons.phone_outlined, 'Gọi điện'),
          ]),
          const SizedBox(height: 20),
          const Text('Câu hỏi thường gặp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...faqs.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(f['a']!, style: const TextStyle(fontSize: 13, color: Colors.grey)))],
            ),
          )),
        ]),
      ),
    );
  }

  Widget _action(IconData icon, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ---- VỀ ỨNG DỤNG ----
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Về ứng dụng', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A1A2E), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40)),
          const SizedBox(height: 16),
          const Text('Wallet AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Phiên bản 1.0.0', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          const Text('Quản lý tài chính cá nhân thông minh', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _item(Icons.description_outlined, 'Điều khoản sử dụng'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
              _item(Icons.privacy_tip_outlined, 'Chính sách bảo mật'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
              _item(Icons.star_outline, 'Đánh giá ứng dụng'),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
              _item(Icons.share_outlined, 'Chia sẻ ứng dụng'),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('© 2026 Wallet AI. All rights reserved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }

  static Widget _item(IconData icon, String title) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: () {},
  );
}
