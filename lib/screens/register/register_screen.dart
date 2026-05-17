import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/snackbar.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// ===== MAP ERROR =====
  String _mapError(String error) {
    if (error.contains("rate limit")) {
      return "Bạn thao tác quá nhanh. Vui lòng thử lại sau vài phút.";
    }

    if (error.contains("User already registered")) {
      return "Email này đã được đăng ký.";
    }

    if (error.contains("Invalid login credentials")) {
      return "Email hoặc mật khẩu không đúng.";
    }

    if (error.contains("Password")) {
      return "Mật khẩu phải ít nhất 6 ký tự.";
    }

    return "Đăng ký thất bại. Vui lòng thử lại.";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff3B82F6), Color(0xff2563EB)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.appTagline,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(title: context.l10n.monthlyContribution, value: '₫3.2M'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(title: context.l10n.members, value: '10K+'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(title: 'AI', value: '95%'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ================= FEATURE =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: const [
                  FeatureCard(
                    icon: Iconsax.chart_2,
                    title: "AI Phân loại",
                    description: "Tự động nhận diện chi tiêu",
                  ),
                  SizedBox(height: 10),
                  FeatureCard(
                    icon: Iconsax.trend_up,
                    title: "Theo dõi",
                    description: "Phân tích xu hướng tài chính",
                  ),
                  SizedBox(height: 10),
                  FeatureCard(
                    icon: Iconsax.flag,
                    title: "Mục tiêu",
                    description: "Hướng tới tự do tài chính",
                  ),
                  SizedBox(height: 10),
                  FeatureCard(
                    icon: Iconsax.cpu,
                    title: "AI Advisor",
                    description: "Tư vấn tài chính cá nhân",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// ================= FORM =================
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.register,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// NAME
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: context.l10n.fullName,
                      prefixIcon: const Icon(Iconsax.user),
                      filled: true,
                      fillColor: const Color(0xffF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// EMAIL
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: context.l10n.email,
                      prefixIcon: const Icon(Iconsax.sms),
                      filled: true,
                      fillColor: const Color(0xffF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: context.l10n.password,
                      helperText: context.l10n.enterPassword,
                      prefixIcon: const Icon(Iconsax.lock),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
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

                  const SizedBox(height: 20),

                  /// ERROR
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _mapError(auth.error!),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  /// BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: const Color(0xff2F80ED),
                      ),
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              final name =
                                  _nameController.text.trim();
                              final email =
                                  _emailController.text.trim();
                              final password =
                                  _passwordController.text.trim();

                              if (name.isEmpty ||
                                  email.isEmpty ||
                                  password.isEmpty) {
                                AppSnackBar.warning(context, 'Vui lòng nhập đầy đủ thông tin');
                                return;
                              }

                              if (!email.contains('@')) {
                                AppSnackBar.warning(context, 'Email không hợp lệ');
                                return;
                              }

                              if (password.length < 6) {
                                AppSnackBar.warning(context, 'Mật khẩu phải ít nhất 6 ký tự');
                                return;
                              }

                              await auth.signUp(
                                fullName: name,
                                email: email,
                                password: password,
                              );

                              if (auth.error == null &&
                                  context.mounted) {
                                AppSnackBar.success(context, 'Đăng ký thành công! Bạn có thể đăng nhập ngay');

                                Future.delayed(
                                    const Duration(seconds: 1), () {
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                        context, '/login');
                                  }
                                });
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
                              context.l10n.registerBtn,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// DIVIDER
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          context.l10n.locale.languageCode == 'vi' ? 'hoặc' : 'or',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// GOOGLE SIGN IN
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        side: const BorderSide(color: Color(0xffE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await auth.signInWithGoogle();
                              // Navigation handled by onAuthStateChange listener
                              if (auth.error != null &&
                                  context.mounted) {
                                AppSnackBar.warning(
                                    context, auth.error!);
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mail_outline,
                              color: Color(0xffEA4335), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            auth.isLoading
                                ? context.l10n.loading
                                : context.l10n.loginWithGoogle,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// LOGIN
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, '/login');
                    },
                    child: Text(
                      context.l10n.alreadyHaveAccount,
                      style: TextStyle(
                        color: Color(0xff2F80ED),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}