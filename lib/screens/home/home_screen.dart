import 'dart:async';
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
import '../../providers/bank_provider.dart';
import '../../providers/shared_fund_provider.dart';
import '../ai/ai_chat_screen.dart';
import '../expense/expense_screen.dart';
import '../goal/goals_screen.dart';
import '../statistic/statistic_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../bank/link_bank_screen.dart';
import '../friend/friends_screen.dart';
import '../fund/shared_funds_screen.dart';
import '../fund/fund_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool showBalance = true;
  bool showNoti = false;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
    _startSyncTimer();
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _runAutoSync());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runAutoSync();
    }
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<WalletProvider>().loadWallets();
        await context.read<TransactionProvider>().loadTransactions();
        context.read<NotificationProvider>().loadNotifications();
        context.read<SharedFundProvider>().loadFunds();
        context.read<SharedFundProvider>().loadInvitations();
        context.read<AuthProvider>().loadProfile();

        /// Lắng nghe thay đổi real-time từ Supabase (webhook SePay, sync...)
        context.read<WalletProvider>().subscribeRealtime();
        context.read<TransactionProvider>().subscribeRealtime();

        /// Auto-sync giao dịch ngân hàng ngay khi mở app
        _runAutoSync();

        // Build financial context for AI
        _buildAndSetFinancialContext(user.id);
      });
    }
  }

  /// ================= AUTO SYNC =================
  Future<void> _runAutoSync() async {
    if (!mounted) return;
    try {
      await context.read<BankProvider>().loadAccounts();
      final synced = await context.read<BankProvider>().autoSyncAll();
      if (synced > 0 && mounted) {
        await context.read<TransactionProvider>().loadTransactions();
        await context.read<WalletProvider>().loadWallets();
      }
    } catch (_) {
      // Bỏ qua lỗi — không làm phiền user
    }
  }

  /// 🔥 BUILD FINANCIAL CONTEXT
  void _buildAndSetFinancialContext(String userId) {
    final walletProvider = this.context.read<WalletProvider>();
    final transProvider = this.context.read<TransactionProvider>();

    final totalBalance = walletProvider.totalBalance;
    final totalIncome = transProvider.totalIncome;
    final totalExpense = transProvider.totalExpense;

    final walletsInfo = walletProvider.wallets.map((w) =>
      '- ${w.name}: ${Formatters.currency(w.balance.toDouble())}'
    ).join('\n');

    final recentExpenses = transProvider.transactions
        .where((t) => t.type == TransactionType.expense)
        .take(5)
        .map((t) => '- ${(t.note != null && t.note!.isNotEmpty) ? t.note : t.categoryId}: ${Formatters.currency(t.amount.toDouble())}')
        .join('\n');

    final financialContext = 'Tổng số dư: ${Formatters.currency(totalBalance.toDouble())}\n'
        'Tổng thu nhập: ${Formatters.currency(totalIncome.toDouble())}\n'
        'Tổng chi tiêu: ${Formatters.currency(totalExpense.toDouble())}\n'
        'Danh sách ví:\n$walletsInfo\n'
        'Chi tiêu gần đây:\n$recentExpenses';

    final authProvider = this.context.read<AuthProvider>();
    final aiProvider = this.context.read<AiProvider>();
    aiProvider.setFinancialContext(financialContext);
    aiProvider.setUserName(authProvider.profile?.fullName);
    aiProvider.loadInsights(userId); // Chỉ load 1 lần (có flag)
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

          const SizedBox(height: 10),

          /// QUICK ACTIONS ROW 2
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LinkBankScreen())),
                  child: const ActionItem(
                      Iconsax.bank, Colors.teal, "Ngân hàng"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen())),
                  child: const ActionItem(
                      Iconsax.people, Colors.purple, "Bạn bè"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SharedFundsScreen())),
                  child: const ActionItem(
                      Iconsax.money_send, Colors.orange, "Quỹ chung"),
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

          /// SHARED FUNDS SECTION
          _buildSharedFundsSection(),

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
                    title: t.displayTitle,
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

  /// ================= SHARED FUNDS SECTION =================
  Widget _buildSharedFundsSection() {
    final fundProvider = context.watch<SharedFundProvider>();
    final funds = fundProvider.activeFunds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Quỹ chung",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SharedFundsScreen())),
              child: const Text("Xem tất cả",
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (funds.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Iconsax.people, size: 36, color: Colors.grey[400]),
                const SizedBox(height: 8),
                const Text("Chưa có quỹ chung",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SharedFundsScreen())),
                  child: const Text("Tạo quỹ mới →",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        else
          ...funds.take(2).map((fund) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FundDetailScreen(fundId: fund.id)),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Iconsax.people,
                                color: Colors.orange, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fund.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text('${fund.memberCount} thành viên',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '${(fund.progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fund.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.orange),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(Formatters.currency(fund.currentAmount),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange)),
                          Text(Formatters.currency(fund.targetAmount),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
      ],
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
