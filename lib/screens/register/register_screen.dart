import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Theo dõi chi tiêu, AI phân loại tự động",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 20),

                  /// STAT
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
                      "Tạo tài khoản",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// INPUT NAME
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Họ và tên",
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

                  /// INPUT EMAIL
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Email",
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

                  /// INPUT PASSWORD
                  TextField(
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Mật khẩu",
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
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text(
                        "Đăng ký",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// LOGIN TEXT
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      "Đã có tài khoản? Đăng nhập",
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