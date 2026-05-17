import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/shared_fund_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/wallet.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';

class FundDetailScreen extends StatefulWidget {
  final String fundId;

  const FundDetailScreen({super.key, required this.fundId});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SharedFundProvider>();
    provider.loadFundDetail(widget.fundId);
    provider.loadFundReminder(widget.fundId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SharedFundProvider>();
    final fund = provider.selectedFund;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (provider.isLoading && fund == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quỹ chung')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (fund == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quỹ chung')),
        body: const Center(child: Text('Không tìm thấy quỹ')),
      );
    }

    final isCreator = fund.creatorId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(fund.name),
        elevation: 0,
        actions: [
          if (isCreator)
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'add_member',
                  child: Text('Thêm thành viên'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa quỹ', style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (val) {
                if (val == 'add_member') _showAddMemberDialog();
                if (val == 'delete') _handleDeleteFund();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadFundDetail(widget.fundId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= PROGRESS CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff3B82F6), Color(0xff2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      Formatters.currency(fund.currentAmount),
                      style: TextStyle(
                        color: fund.currentAmount > fund.targetAmount
                            ? const Color(0xffFBBF24)
                            : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mục tiêu: ${Formatters.currency(fund.targetAmount)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fund.currentAmount > fund.targetAmount ? 1.0 : fund.progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(
                          fund.currentAmount > fund.targetAmount
                              ? const Color(0xffFBBF24)
                              : Colors.white,
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (fund.currentAmount > fund.targetAmount) ...[  
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xffFBBF24).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xffFBBF24), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: Color(0xffFBBF24), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Vượt mục tiêu: +${Formatters.currency(fund.currentAmount - fund.targetAmount)}',
                              style: const TextStyle(
                                color: Color(0xffFBBF24),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[  
                      Text(
                        '${(fund.progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),

              if (fund.description != null && fund.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(fund.description!, style: const TextStyle(color: Colors.grey)),
              ],

              if (fund.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Iconsax.calendar, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Hạn chót: ${Formatters.date(fund.deadline!)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              /// ================= MEMBERS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thành viên (${fund.members.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...fund.members.map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: m.isAdmin
                            ? Colors.amber.withValues(alpha: 0.2)
                            : const Color(0xff2F80ED).withValues(alpha: 0.1),
                        child: Text(
                          (m.userName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: m.isAdmin ? Colors.amber[800] : const Color(0xff2F80ED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(m.userName ?? 'Người dùng'),
                          if (m.isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(fontSize: 10, color: Colors.amber),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('Đã góp: ${Formatters.currency(m.contributedAmount)}'),
                    ),
                  )),

              const SizedBox(height: 24),

              /// ================= CONTRIBUTE + REMINDER BUTTONS =================
              if (fund.isActive)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Iconsax.money_send),
                        label: const Text('Góp quỹ'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color(0xff2F80ED),
                        ),
                        onPressed: () => _showContributeDialog(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Iconsax.notification),
                      label: const Text('Nhắc'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () => _showReminderDialog(),
                    ),
                  ],
                ),

              /// ACTIVE REMINDER INFO
              if (provider.currentReminder != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.notification, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhắc ${provider.currentReminder!.frequencyLabel.toLowerCase()}'
                          ' · ${provider.currentReminder!.scheduleLabel}'
                          ' · ${Formatters.currency(provider.currentReminder!.amount)}',
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await context.read<SharedFundProvider>()
                              .deleteReminder(provider.currentReminder!.id);
                          if (mounted) AppSnackBar.success(context, 'Đã tắt lời nhắc');
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              /// ================= TRANSACTIONS =================
              const Text(
                'Lịch sử góp quỹ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (provider.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...provider.transactions.map((t) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          child: const Icon(Iconsax.money_recive, color: Colors.green),
                        ),
                        title: Text(t.userName ?? 'Người dùng'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Formatters.dateTime(t.createdAt)),
                            if (t.note != null && t.note!.isNotEmpty)
                              Text(t.note!, style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Text(
                          '+${Formatters.currency(t.amount)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= CONTRIBUTE DIALOG =================
  void _showContributeDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final wallets = context.read<WalletProvider>().wallets;
    Wallet? selectedWallet = wallets.isNotEmpty ? wallets.first : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Góp quỹ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// CHỌN VÍ
                DropdownButtonFormField<Wallet>(
                  value: selectedWallet,
                  decoration: InputDecoration(
                    labelText: 'Chọn ví',
                    prefixIcon: const Icon(Iconsax.wallet_3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: wallets.map((w) => DropdownMenuItem(
                    value: w,
                    child: Text('${w.icon} ${w.name} · ${Formatters.currency(w.balance.toDouble())}'),
                  )).toList(),
                  onChanged: (w) => setDialogState(() => selectedWallet = w),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tiền',
                    suffixText: '₫',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedWallet == null) {
                    AppSnackBar.warning(context, 'Vui lòng chọn ví');
                    return;
                  }
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    AppSnackBar.warning(context, 'Số tiền không hợp lệ');
                    return;
                  }
                  if (amount > selectedWallet!.balance) {
                    AppSnackBar.warning(context, 'Số dư ví không đủ');
                    return;
                  }

                  Navigator.pop(ctx);

                  final ok = await context.read<SharedFundProvider>().contribute(
                        fundId: widget.fundId,
                        amount: amount,
                        walletId: selectedWallet!.id,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );

                  if (mounted) {
                    if (ok) {
                      await context.read<WalletProvider>().loadWallets();
                      await context.read<TransactionProvider>().loadTransactions();
                      if (mounted) AppSnackBar.success(context, 'Góp quỹ thành công!');
                    } else {
                      AppSnackBar.error(context,
                          context.read<SharedFundProvider>().error ?? 'Lỗi góp quỹ');
                    }
                  }
                },
                child: const Text('Góp'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ================= REMINDER DIALOG =================
  void _showReminderDialog() {
    final amountController = TextEditingController();
    String frequency = 'monthly';
    int dayOfWeek = 2;   // Thứ 2
    int dayOfMonth = 1;  // Ngày 1

    final existing = context.read<SharedFundProvider>().currentReminder;
    if (existing != null) {
      amountController.text = existing.amount.toStringAsFixed(0);
      frequency = existing.frequency;
      if (existing.dayOfWeek != null) dayOfWeek = existing.dayOfWeek!;
      if (existing.dayOfMonth != null) dayOfMonth = existing.dayOfMonth!;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Lời nhắc góp quỹ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// TẦN SUẤT
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: InputDecoration(
                    labelText: 'Tần suất',
                    prefixIcon: const Icon(Iconsax.clock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                    DropdownMenuItem(value: 'monthly', child: Text('Hàng tháng')),
                  ],
                  onChanged: (v) => setDialogState(() => frequency = v ?? 'monthly'),
                ),
                const SizedBox(height: 12),

                /// NGÀY CỤ THỂ
                if (frequency == 'weekly')
                  DropdownButtonFormField<int>(
                    value: dayOfWeek,
                    decoration: InputDecoration(
                      labelText: 'Ngày trong tuần',
                      prefixIcon: const Icon(Iconsax.calendar),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Thứ 2')),
                      DropdownMenuItem(value: 2, child: Text('Thứ 3')),
                      DropdownMenuItem(value: 3, child: Text('Thứ 4')),
                      DropdownMenuItem(value: 4, child: Text('Thứ 5')),
                      DropdownMenuItem(value: 5, child: Text('Thứ 6')),
                      DropdownMenuItem(value: 6, child: Text('Thứ 7')),
                      DropdownMenuItem(value: 7, child: Text('Chủ nhật')),
                    ],
                    onChanged: (v) => setDialogState(() => dayOfWeek = v ?? 2),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: dayOfMonth,
                    decoration: InputDecoration(
                      labelText: 'Ngày trong tháng',
                      prefixIcon: const Icon(Iconsax.calendar),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: List.generate(28, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Ngày ${i + 1}'),
                    )),
                    onChanged: (v) => setDialogState(() => dayOfMonth = v ?? 1),
                  ),
                const SizedBox(height: 12),

                /// SỐ TIỀN
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tiền nhắc góp',
                    suffixText: '₫',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (existing != null)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context.read<SharedFundProvider>()
                        .deleteReminder(existing.id);
                    if (mounted) AppSnackBar.success(context, 'Đã tắt lời nhắc');
                  },
                  child: const Text('Tắt nhắc', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    AppSnackBar.warning(context, 'Số tiền không hợp lệ');
                    return;
                  }

                  Navigator.pop(ctx);

                  final ok = await context.read<SharedFundProvider>().setReminder(
                    fundId: widget.fundId,
                    frequency: frequency,
                    amount: amount,
                    dayOfWeek: frequency == 'weekly' ? dayOfWeek : null,
                    dayOfMonth: frequency == 'monthly' ? dayOfMonth : null,
                  );

                  if (ok && mounted) {
                    AppSnackBar.success(context, 'Đã đặt lời nhắc!');
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ================= ADD MEMBER DIALOG =================
  void _showAddMemberDialog() {
    final friendProvider = context.read<FriendProvider>();
    friendProvider.loadAll();

    showDialog(
      context: context,
      builder: (_) => Consumer<FriendProvider>(
        builder: (ctx, fp, _) {
          final fund = context.read<SharedFundProvider>().selectedFund;
          final existingIds = fund?.members.map((m) => m.userId).toSet() ?? {};

          final availableFriends = fp.friends
              .where((f) => !existingIds.contains(f.friendId) && !existingIds.contains(f.userId))
              .toList();

          return AlertDialog(
            title: const Text('Thêm thành viên'),
            content: availableFriends.isEmpty
                ? const Text('Không có bạn bè nào để thêm')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableFriends.length,
                      itemBuilder: (_, i) {
                        final f = availableFriends[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text((f.friendName ?? 'U')[0].toUpperCase()),
                          ),
                          title: Text(f.friendName ?? 'Người dùng'),
                          trailing: IconButton(
                            icon: const Icon(Iconsax.add_circle, color: Color(0xff2F80ED)),
                            onPressed: () async {
                              final fund = context.read<SharedFundProvider>().selectedFund;
                              final ok = await context
                                  .read<SharedFundProvider>()
                                  .inviteMember(widget.fundId, f.friendId, fund?.name ?? '');
                              if (ok && mounted) {
                                Navigator.pop(context);
                                AppSnackBar.success(context, 'Đã gửi lời mời');
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ================= DELETE FUND =================
  void _handleDeleteFund() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa quỹ?'),
        content: const Text('Hành động này không thể hoàn tác. Bạn có chắc chắn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context.read<SharedFundProvider>().deleteFund(widget.fundId);
      if (ok && mounted) {
        AppSnackBar.success(context, 'Đã xóa quỹ');
        Navigator.pop(context);
      }
    }
  }
}
