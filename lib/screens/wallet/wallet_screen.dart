import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../models/category.dart' as model;
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import '../../utils/snackbar.dart';
import '../bank/link_bank_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _hideBalance = false;

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
        context.read<AiProvider>().loadInsights(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final transProvider = context.watch<TransactionProvider>();
    final aiProvider = context.watch<AiProvider>();

    final wallets = walletProvider.wallets;
    final transactions = transProvider.transactions;
    final totalBalance = walletProvider.totalBalance;
    final latestInsight = aiProvider.insights.isNotEmpty
        ? aiProvider.insights.first.content
        : "Hãy quản lý các ví của bạn một cách thông minh.";

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => _initData(),
        child: Column(
          children: [
            /// ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ví tiền",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      GestureDetector(
                        onTap: () => setState(() => _hideBalance = !_hideBalance),
                        child: Icon(
                          _hideBalance ? Iconsax.eye_slash : Iconsax.eye,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Tổng số dư",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _hideBalance
                        ? "••••••••"
                        : Formatters.currency(totalBalance.toDouble()),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _headerButton("Chuyển tiền", Iconsax.arrow_up, () {
                          _showTransferSheet(context, wallets);
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _headerButton("Nhận tiền", Iconsax.arrow_down, () {
                          Navigator.pushNamed(context, '/add-transaction');
                        }),
                      ),
                    ],
                  )
                ],
              ),
            ),

            /// ================= BODY =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  /// AI CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffEAF3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.cpu, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("AI gợi ý",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                latestInsight,
                                style: const TextStyle(
                                    color: Colors.blueGrey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ACCOUNTS HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tài khoản của tôi",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      GestureDetector(
                        onTap: () => _showAddWalletSheet(context),
                        child: const Text("+ Thêm",
                            style: TextStyle(
                                color: Colors.blue, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// 💡 HINT
                  const Text("💡 Giữ lâu để chỉnh sửa hoặc xoá ví",
                      style: TextStyle(color: Color(0xff9CA3AF), fontSize: 10)),
                  const SizedBox(height: 8),

                  /// ACCOUNT LIST
                  if (wallets.isEmpty)
                    const Center(
                        child: Text("Chưa có ví nào",
                            style: TextStyle(color: Colors.grey)))
                  else
                    ...wallets.map((w) => GestureDetector(
                          onLongPress: () => _showWalletOptions(context, w),
                          child: _accountItem(
                            w.name,
                            w.balance.toString(),
                            Formatters.currency(w.balance.toDouble()),
                            w.icon,
                          ),
                        )),

                  const SizedBox(height: 20),

                  /// TRANSACTIONS
                  const Text("Hoạt động gần đây",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                  if (transactions.isEmpty)
                    const Center(
                        child: Text("Chưa có hoạt động nào",
                            style: TextStyle(color: Colors.grey)))
                  else
                    ...transactions.take(10).map((t) {
                      final isIncome = t.type == model.TransactionType.income;
                      return _transactionItem(
                        transaction: t,
                        title: t.displayTitle,
                        date: Formatters.dateShort(t.date),
                        amount:
                            "${isIncome ? '+' : '-'}${Formatters.currency(t.amount.toDouble())}",
                        emoji: Formatters.categoryEmoji(t.category?.icon),
                        isIncome: isIncome,
                      );
                    }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }


  /// ================= HEADER BUTTON =================
  Widget _headerButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  /// ================= ACCOUNT ITEM =================
  Widget _accountItem(String title, String sub, String amount, String emoji) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// ================= TRANSACTION ITEM (with edit/delete) =================
  Widget _transactionItem({
    required Transaction transaction,
    required String title,
    required String date,
    required String amount,
    required String emoji,
    bool isIncome = false,
  }) {
    return GestureDetector(
      onTap: () => _showTransactionOptions(context, transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: isIncome ? const Color(0xff16A34A) : const Color(0xffEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TRANSFER BOTTOM SHEET =================
  void _showTransferSheet(BuildContext context, List<Wallet> wallets) {
    Wallet? fromWallet = wallets.firstOrNull;
    Wallet? toWallet = wallets.length > 1 ? wallets[1] : null;
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Chuyển tiền",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Từ tài khoản",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _dropdownField<Wallet>(
                  value: fromWallet,
                  items: wallets,
                  itemLabel: (w) => "${w.name} - ${Formatters.currency(w.balance.toDouble())}",
                  onChanged: (val) => setModalState(() => fromWallet = val),
                ),
                const SizedBox(height: 16),
                const Text("Đến tài khoản",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _dropdownField<Wallet>(
                  value: toWallet,
                  items: wallets,
                  itemLabel: (w) => w.name,
                  onChanged: (val) => setModalState(() => toWallet = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Số tiền chuyển (₫)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = int.tryParse(
                          amountController.text.replaceAll(',', '').replaceAll('.', '')) ??
                          0;

                      // Dùng provider validation
                      final error = context.read<WalletProvider>().validateTransfer(
                        fromWallet?.id, toWallet?.id, amount,
                      );
                      if (error != null) {
                        AppSnackBar.warning(context, error);
                        return;
                      }

                      try {
                        await context.read<WalletProvider>().transfer(
                              fromWalletId: fromWallet!.id,
                              toWalletId: toWallet!.id,
                              amount: amount,
                            );

                        if (mounted) {
                          Navigator.pop(ctx);
                          AppSnackBar.success(context, 'Chuyển tiền thành công');
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.error(context, 'Lỗi: $e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2F80ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Xác nhận chuyển",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= WALLET OPTIONS (Long Press) =================
  void _showWalletOptions(BuildContext context, Wallet w) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(w.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(Formatters.currency(w.balance.toDouble()),
                          style: const TextStyle(color: Color(0xff2F80ED), fontWeight: FontWeight.bold)),
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
                  _showEditWalletSheet(context, w);
                },
                icon: const Icon(Iconsax.edit, size: 18),
                label: const Text("Chỉnh sửa ví"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff2F80ED),
                  side: const BorderSide(color: Color(0xff2F80ED)),
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
                  _showDeleteWalletConfirm(context, w);
                },
                icon: const Icon(Iconsax.trash, size: 18),
                label: const Text("Xoá ví"),
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

  /// ================= EDIT WALLET BOTTOM SHEET =================

  void _showEditWalletSheet(BuildContext context, Wallet w) {
    final nameController = TextEditingController(text: w.name);
    String selectedType = w.type;
    String selectedEmoji = w.icon;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Chỉnh sửa ví",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// ICON VÍ
                const Text("Icon ví",
                    style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.walletEmojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final em = AppConstants.walletEmojis[i];
                      final isSelected = em == selectedEmoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = em),
                        child: Container(
                          width: 44, height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xff2F80ED) : const Color(0xffF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(em, style: TextStyle(fontSize: 20, color: isSelected ? Colors.white : null)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                /// TÊN VÍ
                const Text("Tên ví",
                    style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration('VD: Tài khoản ACB'),
                ),
                const SizedBox(height: 16),

                /// LOẠI VÍ
                const Text("Loại ví",
                    style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: AppConstants.walletTypes.map((t) {
                    final selected = t == selectedType;
                    return ChoiceChip(
                      label: Text(t),
                      selected: selected,
                      selectedColor: const Color(0xff2F80ED),
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                      onSelected: (_) => setModalState(() => selectedType = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        AppSnackBar.warning(context, 'Vui lòng nhập tên ví');
                        return;
                      }

                      try {
                        await context.read<WalletProvider>().updateWallet(
                          w.id,
                          {
                            'name': name,
                            'icon': selectedEmoji,
                          },
                        );

                        if (mounted) {
                          Navigator.pop(ctx);
                          AppSnackBar.success(context, 'Đã cập nhật ví "$name"');
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.error(context, 'Lỗi: $e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2F80ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Lưu thay đổi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= DELETE WALLET CONFIRM =================
  void _showDeleteWalletConfirm(BuildContext context, Wallet w) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xoá ví"),
        content: Text('Bạn có chắc muốn xoá ví "${w.name}"? Tất cả giao dịch trong ví cũng sẽ bị xoá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await context.read<WalletProvider>().deleteWallet(w.id);
                if (mounted) {
                  Navigator.pop(ctx);
                  AppSnackBar.success(context, 'Đã xoá ví "${w.name}"');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  AppSnackBar.error(context, 'Lỗi: $e');
                }
              }
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  /// ================= ADD WALLET BOTTOM SHEET =================
  void _showAddWalletSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = AppConstants.walletTypes.first;
    String selectedEmoji = AppConstants.walletEmojis.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Thêm ví mới",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// ICON VÍ
                const Text("Icon ví",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.walletEmojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final em = AppConstants.walletEmojis[i];
                      final isSelected = em == selectedEmoji;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedEmoji = em),
                        child: Container(
                          width: 44, height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xff2F80ED) : const Color(0xffF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(em, style: TextStyle(fontSize: 20, color: isSelected ? Colors.white : null)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                /// TÊN VÍ
                const Text("Tên ví",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: _inputDecoration('VD: Tài khoản ACB'),
                ),
                const SizedBox(height: 16),

                /// LOẠI VÍ
                const Text("Loại ví",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: AppConstants.walletTypes.map((t) {
                    final selected = t == selectedType;
                    return ChoiceChip(
                      label: Text(t),
                      selected: selected,
                      selectedColor: const Color(0xff2F80ED),
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                      onSelected: (_) => setModalState(() => selectedType = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                /// SỐ DƯ
                const Text("Số dư ban đầu",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('VD: 5000000'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final amount = int.tryParse(
                              amountController.text.replaceAll(',', '').replaceAll('.', '')) ??
                          0;
                      if (name.isEmpty) {
                        AppSnackBar.warning(context, 'Vui lòng nhập tên ví');
                        return;
                      }

                      try {
                        final newWallet = await context.read<WalletProvider>().addWallet(
                              name: name,
                              type: selectedType,
                              balance: amount,
                              icon: selectedEmoji,
                            );

                        if (mounted) {
                          Navigator.pop(ctx);
                          AppSnackBar.success(context, 'Đã thêm ví "$name"');

                          /// Khuyến khích liên kết ngân hàng nếu là ví ngân hàng/điện tử
                          if (selectedType == 'Ngân hàng' || selectedType == 'Ví điện tử') {
                            await Future.delayed(const Duration(milliseconds: 300));
                            if (mounted) _promptLinkBank(newWallet.id, name);
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.error(context, 'Lỗi: $e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2F80ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Thêm ví",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= PROMPT LINK BANK =================
  void _promptLinkBank(String walletId, String walletName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff2F80ED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance, color: Color(0xff2F80ED)),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Liên kết ngân hàng', style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(
          'Liên kết ví "$walletName" với tài khoản ngân hàng để tự động đồng bộ số dư và giao dịch!',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Liên kết ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2F80ED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LinkBankScreen(preselectedWalletId: walletId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// ================= TRANSACTION OPTIONS (Edit / Delete) =================
  void _showTransactionOptions(BuildContext context, Transaction t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.note ?? t.category?.name ?? "Giao dịch",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(Formatters.currency(t.amount.toDouble()),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: t.type == model.TransactionType.income ? Colors.green : Colors.red,
                )),
            const SizedBox(height: 4),
            Text(Formatters.date(t.date), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showEditTransactionSheet(context, t);
                },
                icon: const Icon(Iconsax.edit, size: 18),
                label: const Text("Chỉnh sửa giao dịch"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff2F80ED),
                  side: const BorderSide(color: Color(0xff2F80ED)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(context, t);
                },
                icon: const Icon(Iconsax.trash, size: 18),
                label: const Text("Xoá giao dịch"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= EDIT TRANSACTION =================
  void _showEditTransactionSheet(BuildContext context, Transaction t) {
    final titleCtrl = TextEditingController(text: t.note ?? t.category?.name);
    final amountCtrl = TextEditingController(text: t.amount.abs().toString());
    model.TransactionType selectedType = t.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Chỉnh sửa giao dịch",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Tên giao dịch",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(controller: titleCtrl, decoration: _inputDecoration('Tên giao dịch')),
                const SizedBox(height: 16),
                const Text("Số tiền",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Số tiền (₫)'),
                ),
                const SizedBox(height: 16),
                const Text("Loại",
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Thu nhập"),
                        selected: selectedType == model.TransactionType.income,
                        selectedColor: Colors.green.shade100,
                        onSelected: (_) =>
                            setModalState(() => selectedType = model.TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Chi tiêu"),
                        selected: selectedType == model.TransactionType.expense,
                        selectedColor: Colors.red.shade100,
                        onSelected: (_) =>
                            setModalState(() => selectedType = model.TransactionType.expense),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = int.tryParse(
                              amountCtrl.text.replaceAll(',', '').replaceAll('.', '')) ??
                          0;

                      // Dùng provider method thay vì tạo Transaction object
                      await context.read<TransactionProvider>().updateTransactionFields(
                        t.id,
                        type: selectedType,
                        amount: amount,
                        note: titleCtrl.text.trim(),
                      );
                      
                      if (mounted) {
                        context.read<WalletProvider>().loadWallets();
                        Navigator.pop(ctx);
                        AppSnackBar.success(context, 'Đã cập nhật giao dịch');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2F80ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Lưu thay đổi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= DELETE CONFIRM =================
  void _showDeleteConfirm(BuildContext context, Transaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xoá giao dịch"),
        content: Text('Bạn có chắc muốn xoá "${t.note ?? t.category?.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await context.read<TransactionProvider>().deleteTransaction(t.id);
              if (mounted) {
                context.read<WalletProvider>().loadWallets();
                Navigator.pop(ctx);
                AppSnackBar.success(context, 'Đã xoá giao dịch');
              }
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// ================= HELPERS =================
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff2F80ED)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _dropdownField<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: const Text("Chọn"),
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
