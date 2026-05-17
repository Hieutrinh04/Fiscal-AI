import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/goal_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/goal.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';
import '../../l10n/app_localizations.dart';
import '../ai/ai_chat_screen.dart';

/// 🔥 COLOR SYSTEM
const primaryColor = Color(0xff2F80ED);
const secondaryColor = Color(0xff56CCF2);

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<String> iconOptions = [
    '🏠',
    '✈️',
    '🛡️',
    '🎓',
    '🚗',
    '💍',
    '📱',
    '💼',
    '🏖️',
    '🎯'
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GoalProvider>().loadGoals();
        context.read<AiProvider>().loadInsights(user.id);
      });
    }
  }

  /// Modal chỉ thu thập dữ liệu, trả về result — async work chạy ở parent
  Future<void> _showDepositDialog(Goal goal) async {
    final wallets = context.read<WalletProvider>().wallets;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _DepositSheet(goal: goal, wallets: wallets),
    );

    if (result == null || !mounted) return;

    final amount = result['amount'] as int;
    final wallet = result['wallet'] as Wallet;
    final txProvider = context.read<TransactionProvider>();
    final goalProv = context.read<GoalProvider>();
    final walletProv = context.read<WalletProvider>();

    try {
      final now = DateTime.now();
      await txProvider.addTransaction(Transaction(
        id: '', userId: '',
        walletId: wallet.id,
        type: TransactionType.expense,
        amount: amount,
        note: 'Tiết kiệm: ${goal.name}',
        date: now, createdAt: now, updatedAt: now,
      ));
      await goalProv.addAmount(goal.id, amount);
      await walletProv.loadWallets();
      if (mounted) {
        AppSnackBar.success(context,
            'Đã góp ${Formatters.currency(amount.toDouble())} vào ${goal.name}');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Lỗi: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _showAddGoalDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();
    String selectedIcon = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thêm mục tiêu mới',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: iconOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final ic = iconOptions[i];
                    final isSelected = ic == selectedIcon;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedIcon = ic),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border:
                              isSelected ? Border.all(color: primaryColor, width: 2) : null,
                        ),
                        child: Text(ic, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildInput(nameCtrl, 'Tên mục tiêu (VD: Mua xe)'),
              const SizedBox(height: 10),
              _buildInput(targetCtrl, 'Số tiền mục tiêu ()', isNumber: true),
              const SizedBox(height: 10),
              _buildInput(monthlyCtrl, 'Tiết kiệm mỗi tháng ()', isNumber: true),
              const SizedBox(height: 10),
              _buildInput(deadlineCtrl, 'Hạn chót (VD: 2026-12-31)'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final target = int.tryParse(targetCtrl.text) ?? 0;
                    final user = Supabase.instance.client.auth.currentUser;

                    if (name.isEmpty || target == 0 || user == null) {
                      AppSnackBar.warning(context, 'Vui lòng nhập tên và số tiền mục tiêu');
                      return;
                    }

                    final newGoal = Goal(
                      id: '', // Supabase sẽ tự tạo ID
                      userId: user.id,
                      name: name,
                      targetAmount: target,
                      icon: selectedIcon,
                      deadline: DateTime.tryParse(deadlineCtrl.text),
                      createdAt: DateTime.now(),
                    );

                    await context.read<GoalProvider>().addGoal(newGoal);

                    if (mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tạo mục tiêu',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= GOAL OPTIONS (Long Press) =================
  void _showGoalOptions(BuildContext context, Goal g) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(g.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text('${Formatters.currency(g.currentAmount.toDouble())} / ${Formatters.currency(g.targetAmount.toDouble())}',
                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            /// CHỈNH SỬA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditGoalDialog(g);
                },
                icon: const Icon(Iconsax.edit, size: 18),
                label: Text(context.l10n.editGoal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// XOÁ
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDeleteGoalConfirm(g);
                },
                icon: const Icon(Iconsax.trash, size: 18),
                label: Text(context.l10n.deleteGoal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// ================= EDIT GOAL =================
  void _showEditGoalDialog(Goal g) {
    final nameCtrl = TextEditingController(text: g.name);
    final targetCtrl = TextEditingController(text: g.targetAmount.toString());
    final deadlineCtrl = TextEditingController(
      text: g.deadline != null
          ? '${g.deadline!.year}-${g.deadline!.month.toString().padLeft(2, '0')}-${g.deadline!.day.toString().padLeft(2, '0')}'
          : '',
    );
    String selectedIcon = g.icon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chỉnh sửa mục tiêu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),

              /// ICON
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: iconOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final ic = iconOptions[i];
                    final isSelected = ic == selectedIcon;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedIcon = ic),
                      child: Container(
                        width: 44, height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
                        ),
                        child: Text(ic, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              /// TÊN
              _buildInput(nameCtrl, 'Tên mục tiêu (VD: Mua xe)'),
              const SizedBox(height: 10),

              /// SỐ TIỀN MỤC TIÊU
              _buildInput(targetCtrl, 'Số tiền mục tiêu (₫)', isNumber: true),
              const SizedBox(height: 10),

              /// HẠN CHÓT
              _buildInput(deadlineCtrl, 'Hạn chót (VD: 2026-12-31)'),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final target = int.tryParse(targetCtrl.text) ?? 0;

                    if (name.isEmpty || target == 0) {
                      AppSnackBar.warning(context, 'Vui lòng nhập tên và số tiền mục tiêu');
                      return;
                    }

                    // Pop bottom sheet trước để tránh context bị invalid khi provider notifyListeners
                    Navigator.pop(ctx);

                    try {
                      final updatedGoal = g.copyWith(
                        name: name,
                        targetAmount: target,
                        icon: selectedIcon,
                        deadline: DateTime.tryParse(deadlineCtrl.text),
                      );
                      await context.read<GoalProvider>().updateGoal(updatedGoal);
                      if (mounted) {
                        AppSnackBar.success(context, 'Đã cập nhật mục tiêu "$name"');
                      }
                    } catch (e) {
                      if (mounted) {
                        AppSnackBar.error(context, 'Lỗi: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lưu thay đổi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= DELETE GOAL CONFIRM =================
  void _showDeleteGoalConfirm(Goal g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.deleteGoal),
        content: Text(context.l10n.deleteGoalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<GoalProvider>().deleteGoal(g.id);
                if (mounted) {
                  AppSnackBar.success(context, context.l10n.success);
                }
              } catch (e) {
                if (mounted) {
                  AppSnackBar.error(context, '${context.l10n.error}: $e');
                }
              }
            },
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final aiProvider = context.watch<AiProvider>();

    final goals = goalProvider.goals;
    final totalSaved = goals.fold(0, (s, g) => s + g.currentAmount);
    final totalTarget = goals.fold(0, (s, g) => s + g.targetAmount);
    final percent = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;
    final latestInsight = aiProvider.insights.isNotEmpty
        ? aiProvider.insights.first.content
        : context.l10n.aiInsightFallback;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _initData(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text('Mục tiêu tài chính',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.gps_fixed, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text('Tiến độ tự do tài chính',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor)),
                          ]),
                          const SizedBox(height: 8),
                          RichText(
                              text: TextSpan(children: [
                            TextSpan(
                              text: Formatters.currency(totalSaved.toDouble()),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            TextSpan(
                              text: ' / ${Formatters.currency(totalTarget.toDouble())}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ])),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(primaryColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                              text: TextSpan(
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            children: [
                              const TextSpan(text: 'Bạn đã đạt '),
                              TextSpan(
                                text: '${(percent * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, color: primaryColor),
                              ),
                              const TextSpan(text: ' mục tiêu'),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xff1A3558)
                            : const Color(0xffEFF6FF),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Iconsax.magic_star, color: Colors.blue, size: 16),
                              const SizedBox(width: 6),
                              Text(context.l10n.aiInsight,
                                  style: const TextStyle(
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
                            child: Text("${context.l10n.aiAssistant} →",
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (goals.isEmpty)
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(context.l10n.noGoals,
                            style: const TextStyle(color: Colors.grey)),
                      ))
                    else
                      ...goals.map((g) {
                        final pct = (g.currentAmount / g.targetAmount);

                        return GestureDetector(
                          onLongPress: () => _showGoalOptions(context, g),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Row(children: [
                                  Text(g.icon, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  Text('${(pct * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${Formatters.currency(g.currentAmount.toDouble())} / ${Formatters.currency(g.targetAmount.toDouble())}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: pct,
                                  color: primaryColor,
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[200],
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showDepositDialog(g),
                                  child: const Text('+ Nạp tiền',
                                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _showAddGoalDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm mục tiêu mới'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== DEPOSIT SHEET =====
/// Widget riêng biệt — chỉ thu thập dữ liệu và trả về qua Navigator.pop
/// Không chứa bất kỳ async work nào để tránh Flutter Web mouse_tracker bug
class _DepositSheet extends StatefulWidget {
  final Goal goal;
  final List<Wallet> wallets;
  const _DepositSheet({required this.goal, required this.wallets});

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _amountCtrl = TextEditingController();
  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _selectedWallet = widget.wallets.isNotEmpty ? widget.wallets.first : null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')));
      return;
    }
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ví')));
      return;
    }
    if (_selectedWallet!.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số dư ví không đủ (còn ${Formatters.currency(_selectedWallet!.balance.toDouble())})')));
      return;
    }
    Navigator.pop(context, {'amount': amount, 'wallet': _selectedWallet});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Góp tiền vào "${widget.goal.name}"',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến độ: ${Formatters.currency(widget.goal.currentAmount.toDouble())} / ${Formatters.currency(widget.goal.targetAmount.toDouble())}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (widget.wallets.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text('Bạn chưa có ví nào. Tạo ví trước để góp tiền.'),
              )
            else ...[
              const Text('Trừ từ ví:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ...widget.wallets.map((w) => GestureDetector(
                onTap: () => setState(() => _selectedWallet = w),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedWallet?.id == w.id ? primaryColor : Colors.grey.shade300,
                      width: _selectedWallet?.id == w.id ? 2 : 1,
                    ),
                    color: _selectedWallet?.id == w.id ? primaryColor.withOpacity(0.05) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Text(w.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(Formatters.currency(w.balance.toDouble()),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (_selectedWallet?.id == w.id)
                        const Icon(Icons.check_circle, color: primaryColor, size: 20),
                    ],
                  ),
                ),
              )),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Số tiền góp (₫)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: widget.wallets.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}