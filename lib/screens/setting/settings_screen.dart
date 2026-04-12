import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../ai/ai_chat_screen.dart';
import '../wallet/wallet_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),

              /// PROFILE
              _buildProfileCard(),

              /// TÀI KHOẢN
              _buildSectionTitle('TÀI KHOẢN'),
              _buildSettingsGroup([
                _buildSettingTile(
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Thông tin cá nhân',
                  subtitle: 'Zaim Nguyen, zaim@email.com',
                  onTap: () => _showEditProfileModal(context),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Quản lý ví',
                  subtitle: 'Tài khoản ngân hàng, ví điện tử',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.flag_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Mục tiêu tài chính',
                  subtitle: 'Theo dõi tiến độ tiết kiệm',
                  onTap: () {},
                ),
              ]),

              /// TIỆN ÍCH
              _buildSectionTitle('TIỆN ÍCH'),
              _buildSettingsGroup([
                _buildSettingTile(
                  icon: Icons.smart_toy_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'AI Advisor',
                  subtitle: 'Tư vấn tài chính AI',
                  trailing: _buildBadge('Mới'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AIChatScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Thông báo',
                  subtitle:
                      _notificationEnabled ? 'Đang bật' : 'Đang tắt',
                  value: _notificationEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationEnabled = val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Chế độ tối',
                  subtitle:
                      _darkModeEnabled ? 'Đang bật' : 'Đang tắt',
                  value: _darkModeEnabled,
                  onChanged: (val) =>
                      setState(() => _darkModeEnabled = val),
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.language,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Ngôn ngữ',
                  subtitle: 'VN: Tiếng Việt',
                  onTap: () {},
                ),
              ]),

              /// KHÁC
              _buildSectionTitle('KHÁC'),
              _buildSettingsGroup([
                _buildSettingTile(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Bảo mật',
                  subtitle: 'Mật khẩu, xác thực 2 lớp',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Trợ giúp',
                  subtitle: 'FAQ, liên hệ hỗ trợ',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingTile(
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Về ứng dụng',
                  subtitle: 'Phiên bản 1.0.0',
                  onTap: () {},
                ),
              ]),

              const SizedBox(height: 20),

              /// LOGOUT
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
                        borderRadius: BorderRadius.circular(16),
                      ),
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

  /// ================= PROFILE =================
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showEditProfileModal(context),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF3B82F6),
              child: Text('Z',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zaim Nguyen',
                      style:
                          TextStyle(fontWeight: FontWeight.bold)),
                  Text('zaim@email.com',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right)
          ],
        ),
      ),
    );
  }

  /// ================= POPUP =================
  void _showEditProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chỉnh sửa hồ sơ',
                style:
                    TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const CircleAvatar(radius: 30, child: Text('Z')),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Họ và tên'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Lưu thay đổi'),
            )
          ],
        ),
      ),
    );
  }

  /// ================= COMMON =================
  Widget _buildSectionTitle(String title) =>
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title),
      );

  Widget _buildSettingsGroup(List<Widget> children) =>
      Column(children: children);

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing:
          trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildDivider() => const Divider();

  Widget _buildBadge(String text) => Text(text);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'))
        ],
      ),
    );
  }
}