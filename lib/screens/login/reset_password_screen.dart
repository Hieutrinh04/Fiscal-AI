import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black87),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// ICON
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff2F80ED).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.key,
                    size: 40,
                    color: Color(0xff2F80ED),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// TITLE
              const Text(
                'Đặt mật khẩu mới',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Nhập mật khẩu mới cho tài khoản của bạn.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              /// FORM CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// NEW PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: obscurePassword,
                      enabled: !_success,
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu mới',
                        helperText: 'Tối thiểu 6 ký tự',
                        prefixIcon: const Icon(Iconsax.lock),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => obscurePassword = !obscurePassword),
                          child: Icon(
                            obscurePassword
                                ? Iconsax.eye_slash
                                : Iconsax.eye,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xffF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// CONFIRM PASSWORD
                    TextField(
                      controller: _confirmController,
                      obscureText: obscureConfirm,
                      enabled: !_success,
                      decoration: InputDecoration(
                        hintText: 'Xác nhận mật khẩu',
                        prefixIcon: const Icon(Iconsax.lock_1),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(
                              () => obscureConfirm = !obscureConfirm),
                          child: Icon(
                            obscureConfirm
                                ? Iconsax.eye_slash
                                : Iconsax.eye,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xffF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ERROR
                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    /// SUCCESS
                    if (_success)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Iconsax.tick_circle,
                                color: Colors.green, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Đổi mật khẩu thành công!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!_success) ...[
                      /// BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: const Color(0xff2F80ED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  final password =
                                      _passwordController.text.trim();
                                  final confirm =
                                      _confirmController.text.trim();

                                  if (password.isEmpty ||
                                      confirm.isEmpty) {
                                    AppSnackBar.warning(context,
                                        'Vui lòng nhập đầy đủ thông tin');
                                    return;
                                  }

                                  if (password.length < 6) {
                                    AppSnackBar.warning(context,
                                        'Mật khẩu phải ít nhất 6 ký tự');
                                    return;
                                  }

                                  if (password != confirm) {
                                    AppSnackBar.warning(context,
                                        'Mật khẩu xác nhận không khớp');
                                    return;
                                  }

                                  final ok = await auth.updatePassword(
                                      newPassword: password);

                                  if (ok && mounted) {
                                    setState(() => _success = true);
                                    AppSnackBar.success(context,
                                        'Đổi mật khẩu thành công!');

                                    Future.delayed(
                                        const Duration(seconds: 2), () {
                                      if (mounted) {
                                        Navigator
                                            .pushReplacementNamed(
                                                context, '/home');
                                      }
                                    });
                                  }
                                },
                          child: auth.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Đặt mật khẩu mới',
                                  style: TextStyle(fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// BACK TO LOGIN
              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color: Color(0xff2F80ED),
                      fontWeight: FontWeight.w500,
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
}
