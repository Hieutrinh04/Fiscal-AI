import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../widgets/notification_panel.dart';
import '../ai/ai_chat_screen.dart';
import '../expense/expense_screen.dart';
import '../goal/goals_screen.dart'; // 🔥 THÊM

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showBalance = true;
  bool showNoti = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF3F4F6),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildContent(),
                ],
              ),
            ),

            if (showNoti)
              NotificationPanel(
                onClose: () {
                  setState(() {
                    showNoti = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Xin chào 👋",
                  style: TextStyle(color: Colors.white70)),

              Row(
                children: [
                  /// 🔔 Notification
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showNoti = true;
                      });
                    },
                    child:
                        const Icon(Iconsax.notification, color: Colors.white),
                  ),

                  const SizedBox(width: 12),

                  /// 🤖 AI
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AIChatScreen(),
                        ),
                      );
                    },
                    child: const Icon(Iconsax.cpu, color: Colors.white),
                  ),

                  const SizedBox(width: 12),

                  /// 👁️ Show/Hide balance
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showBalance = !showBalance;
                      });
                    },
                    child: Icon(
                      showBalance ? Iconsax.eye : Iconsax.eye_slash,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text("Zaim Nguyen",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          /// BALANCE CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Số dư hiện tại",
                    style: TextStyle(color: Colors.white70)),

                const SizedBox(height: 6),

                Text(
                  showBalance ? "₫47,000,000" : "••••••",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Row(
                  children: const [
                    Row(
                      children: [
                        Icon(Iconsax.arrow_up_2,
                            color: Color(0xff16A34A), size: 16),
                        SizedBox(width: 5),
                        Text("₫15,000,000",
                            style: TextStyle(color: Color(0xff16A34A))),
                      ],
                    ),
                    SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(Iconsax.arrow_down_1,
                            color: Colors.red, size: 16),
                        SizedBox(width: 5),
                        Text("₫2,150,000",
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CONTENT =================
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// ACTION
          Row(
            children: [
              /// Chi tiêu
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenseScreen(),
                      ),
                    );
                  },
                  child: const ActionItem(
                    Iconsax.arrow_up,
                    Colors.red,
                    "Chi tiêu",
                  ),
                ),
              ),
              const SizedBox(width: 10),

              /// 🔥 Thống kê (chuyển tab)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onNavigate?.call(2);
                  },
                  child: const ActionItem(
                    Iconsax.chart,
                    Colors.blue,
                    "Thống kê",
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// 🔥 Mục tiêu (mở màn hình)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GoalsScreen(),
                      ),
                    );
                  },
                  child: const ActionItem(
                    Iconsax.flag,
                    Colors.green,
                    "Mục tiêu",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// AI CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
              color: const Color(0xffEAF3FF),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Iconsax.cpu, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "AI Insight: Chi tiêu ăn uống tăng 15% so với tháng trước",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AIChatScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Hỏi AI Advisor →",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// TITLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Giao dịch gần đây",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpenseScreen(),
                    ),
                  );
                },
                child: const Text("Xem tất cả",
                    style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// LIST
          Column(
            children: const [
              TransactionItem("Grab Food", "Hôm nay - Ăn uống", "-85.000",
                  Colors.red, Iconsax.shopping_cart),
              TransactionItem("Highland Coffee", "Cafe", "-45.000",
                  Colors.red, Iconsax.coffee),
              TransactionItem("Shopee", "Mua sắm", "-320.000",
                  Colors.red, Iconsax.shop),
              TransactionItem("Lương tháng 3", "Thu nhập", "+15.000.000",
                  Color(0xff16A34A), Iconsax.money_recive),
            ],
          ),
        ],
      ),
    );
  }
}

/// ================= ACTION =================
class ActionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const ActionItem(this.icon, this.color, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}

/// ================= TRANSACTION =================
class TransactionItem extends StatelessWidget {
  final String title;
  final String sub;
  final String amount;
  final Color color;
  final IconData icon;

  const TransactionItem(
      this.title, this.sub, this.amount, this.color, this.icon,
      {super.key});

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tùy chọn giao dịch",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Iconsax.edit),
                title: const Text("Chỉnh sửa"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading:
                    const Icon(Iconsax.trash, color: Colors.red),
                title: const Text("Xóa"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(sub,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(amount,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}