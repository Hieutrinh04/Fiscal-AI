import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/snackbar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// ✅ THÊM: MAP ERROR
  String _mapError(String error) {
    if (error.contains("Invalid login credentials")) {
      return "Email hoặc mật khẩu không đúng.";
    }

    if (error.contains("rate limit")) {
      return "Bạn thao tác quá nhanh. Vui lòng thử lại sau.";
    }

    return "Đăng nhập thất bại. Vui lòng thử lại.";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
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
                children: const [
                  Text(
                    "Trợ Lý Tài Chính AI Cá Nhân",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Theo dõi chi tiêu, AI phân loại tự động",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(title: "Tiết kiệm TB", value: "₫3.2M"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: StatCard(title: "Người dùng", value: "10K+"),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: StatCard(title: "AI chính xác", value: "95%"),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Đăng nhập",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Chào mừng trở lại!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// EMAIL
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      helperText: "Nhập email đã đăng ký", // ✅ THÊM
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
                      hintText: "Mật khẩu",
                      helperText: "Tối thiểu 6 ký tự", // ✅ THÊM
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
                        _mapError(auth.error!), // ✅ FIX
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

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
                              final email =
                                  _emailController.text.trim();
                              final password =
                                  _passwordController.text.trim();

                              /// 
                              if (email.isEmpty ||
                                  password.isEmpty) {
                                AppSnackBar.warning(context, 'Vui lòng nhập đầy đủ thông tin');
                                return;
                              }

                              if (!email.contains('@')) {
                                AppSnackBar.warning(context, 'Email không hợp lệ');
                                return;
                              }

                              await auth.signIn(
                                email: email,
                                password: password,
                              );

                              if (auth.isAuthenticated &&
                                  context.mounted) {
                                Navigator.pushReplacementNamed(
                                    context, '/home');
                              }
                            },
                      child: auth.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Đăng nhập",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// REGISTER
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      "Chưa có tài khoản? Đăng ký",
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