import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';

import '../../widgets/notification_panel.dart';
import '../ai/ai_chat_screen.dart';
import '../expense/expense_screen.dart';
import '../goal/goals_screen.dart';
import '../statistic/statistic_screen.dart';
import '../transaction/add_transaction_screen.dart';

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
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<WalletProvider>().loadWallets();
        context.read<TransactionProvider>().loadTransactions();
        context.read<NotificationProvider>().loadNotifications();
        context.read<AiProvider>().loadInsights(user.id);
        context.read<AuthProvider>().loadProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF3F4F6),
      child: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => _initData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildContent(),
                    const SizedBox(height: 80), // padding cho bottom nav
                  ],
                ),
              ),
            ),
            if (showNoti)
              NotificationPanel(
                onClose: () => setState(() => showNoti = false),
              ),
          ],
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _buildHeader() {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final transProvider = context.watch<TransactionProvider>();
    final notiProvider = context.watch<NotificationProvider>();

    final name = authProvider.profile?.fullName ?? "Người dùng";
    final totalBalance = walletProvider.totalBalance;
    final totalIncome = transProvider.totalIncome;
    final totalExpense = transProvider.totalExpense;
    final unreadNoti = notiProvider.unreadCount;

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
          /// TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Greeting + Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Xin chào 👋",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),

              /// Icons
              Row(
                children: [
                  /// 🔔 Notification với badge
                  GestureDetector(
                    onTap: () => setState(() => showNoti = true),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Iconsax.notification, color: Colors.white),
                        if (unreadNoti > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xff2F80ED), width: 2),
                              ),
                              child: Center(
                                child: Text(unreadNoti.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  /// 👁️ Show/Hide
                  GestureDetector(
                    onTap: () =>
                        setState(() => showBalance = !showBalance),
                    child: Icon(
                      showBalance ? Iconsax.eye : Iconsax.eye_slash,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),

                  /// 🤖 AI
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AIChatScreen()),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Iconsax.cpu, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// BALANCE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Số dư hiện tại",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  showBalance
                      ? Formatters.currency(totalBalance.toDouble())
                      : "••••••••",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    /// Thu nhập
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xff16A34A).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.arrow_down_1,
                          color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Thu nhập",
                            style: TextStyle(
                                color: Colors.white60, fontSize: 10)),
                        Text(Formatters.currency(totalIncome.toDouble()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 24),

                    /// Chi tiêu
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.arrow_up_2,
                          color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Chi tiêu",
                            style: TextStyle(
                                color: Colors.white60, fontSize: 10)),
                        Text(Formatters.currency(totalExpense.toDouble()),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TRANSACTION OPTIONS (Long Press) =================
  void _showTransactionOptions(BuildContext context, Transaction t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: t.type == TransactionType.income
                          ? const Color(0xff16A34A).withOpacity(0.1)
                          : const Color(0xffF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(t.category?.icon ?? "💰",
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.note ?? t.category?.name ?? "Giao dịch",
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          "${t.type == TransactionType.income ? '+' : '-'}${Formatters.currency(t.amount.toDouble())}",
                          style: TextStyle(
                            color: t.type == TransactionType.income
                                ? const Color(0xff16A34A)
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            /// CHỈNH SỬA
            ListTile(
              leading: const Icon(Iconsax.edit, color: Colors.blue),
              title: const Text("Chỉnh sửa giao dịch"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(transaction: t),
                  ),
                );
              },
            ),

            /// XOÁ
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text("Xoá giao dịch",
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Xác nhận xoá"),
                    content: Text(
                        "Bạn có chắc muốn xoá giao dịch \"${t.note ?? t.category?.name ?? 'Giao dịch'}\" không?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Huỷ")),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Xoá",
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  try {
                    await context
                        .read<TransactionProvider>()
                        .deleteTransaction(t.id);
                    if (context.mounted) {
                      await context.read<WalletProvider>().loadWallets();
                      AppSnackBar.success(context, 'Đã xoá giao dịch');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.error(context, 'Lỗi: $e');
                    }
                  }
                }
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// ================= CONTENT =================
  Widget _buildContent() {
    final aiProvider = context.watch<AiProvider>();
    final transProvider = context.watch<TransactionProvider>();
    final transactions = transProvider.transactions;
    final latestInsight = aiProvider.insights.isNotEmpty
        ? aiProvider.insights.first.content
        : "Chào bạn! Tôi là trợ lý tài chính AI. Hãy bắt đầu ghi chép chi tiêu để tôi có thể phân tích cho bạn nhé.";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// QUICK ACTIONS
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                  child: const ActionItem(
                      Iconsax.arrow_up, Colors.red, "Chi tiêu"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!.call(2);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                    );
                  },
                  child: const ActionItem(
                      Iconsax.chart, Colors.blue, "Thống kê"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GoalsScreen())),
                  child: const ActionItem(
                      Iconsax.flag, Colors.green, "Mục tiêu"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// AI INSIGHT CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
              color: const Color(0xffEFF6FF),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Iconsax.magic_star, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text("AI Insight",
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  latestInsight,
                  style: const TextStyle(
                      color: Color(0xff6B7280), fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AIChatScreen())),
                  child: const Text("Hỏi AI Advisor →",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// TRANSACTIONS HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Giao dịch gần đây",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpenseScreen())),
                child: const Text("Xem tất cả",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// 💡 HINT
          const Text("💡 Giữ lâu để chỉnh sửa giao dịch",
              style: TextStyle(color: Color(0xff9CA3AF), fontSize: 10)),

          const SizedBox(height: 10),

          /// TRANSACTION LIST (Dữ liệu thật)
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("Chưa có giao dịch nào",
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...transactions.take(5).map((t) => GestureDetector(
                  onLongPress: () => _showTransactionOptions(context, t),
                  child: TransactionItem(
                    emoji: t.category?.icon ?? "💰",
                    title: t.note ?? t.category?.name ?? "Giao dịch",
                    subtitle:
                        "${Formatters.dateShort(t.date)} · ${t.category?.name ?? 'Khác'}",
                    amount:
                        "${t.type == TransactionType.income ? '+' : '-'}${Formatters.currency(t.amount.toDouble())}",
                    isIncome: t.type == TransactionType.income,
                  ),
                )),
        ],
      ),
    );
  }
}

/// ================= ACTION ITEM =================
class ActionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const ActionItem(this.icon, this.color, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// ================= TRANSACTION ITEM (dùng emoji) =================
class TransactionItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;

  const TransactionItem({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            /// Emoji avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isIncome
                    ? const Color(0xff16A34A).withOpacity(0.1)
                    : const Color(0xffF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),

            /// Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xff9CA3AF), fontSize: 12)),
                ],
              ),
            ),

            /// Amount
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isIncome ? const Color(0xff16A34A) : const Color(0xffEF4444),
              ),
            ),
          ],
        ),
    );
  }
}
