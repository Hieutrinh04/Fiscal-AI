import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/bank_account.dart';
import '../../providers/bank_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/snackbar.dart';

class BankTransactionsScreen extends StatefulWidget {
  final BankAccount account;
  const BankTransactionsScreen({super.key, required this.account});

  @override
  State<BankTransactionsScreen> createState() => _BankTransactionsScreenState();
}

class _BankTransactionsScreenState extends State<BankTransactionsScreen> {
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bank = context.read<BankProvider>();
    await Future.wait([
      bank.fetchTransactions(widget.account.accountNumber),
      bank.fetchAccountInfo(widget.account.accountNumber),
    ]);

    /// Auto-sync lặng lẽ vào DB nếu đã liên kết ví
    if (widget.account.walletId != null && mounted) {
      _autoSyncSilently();
    }
  }

  Future<void> _autoSyncSilently() async {
    try {
      final synced = await context.read<BankProvider>().syncTransactionsToDatabase(
        accountNumber: widget.account.accountNumber,
        walletId: widget.account.walletId!,
      );
      if (synced > 0 && mounted) {
        await context.read<TransactionProvider>().loadTransactions();
        await context.read<WalletProvider>().loadWallets();
      }
    } catch (_) {
      // Bỏ qua lỗi auto-sync — không làm phiền user
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final transactions = bank.transactions;
    final accountInfo = bank.sepayAccountInfo;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.account.bankName} - ${widget.account.accountNumber}'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= ACCOUNT INFO CARD =================
              _buildAccountInfoCard(accountInfo),
              const SizedBox(height: 16),

              /// ================= NO WALLET WARNING =================
              if (widget.account.walletId == null)
                _buildNoWalletBanner(),

              /// ================= TRANSACTIONS =================
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (bank.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (transactions.isEmpty && !bank.isLoading)
                _buildEmptyState()
              else
                ...transactions.map((tx) => _buildTransactionCard(tx)),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= ACCOUNT INFO CARD =================
  Widget _buildAccountInfoCard(Map<String, dynamic>? info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.bank, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.account.bankName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (widget.account.isVerified)
                const Icon(Icons.verified, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.account.accountName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.account.accountNumber,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// ================= LINK WALLET BANNER =================
  Widget _buildNoWalletBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa liên kết ví — giao dịch sẽ không tự động cập nhật số dư',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _linkWallet,
            style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
            child: const Text('Liên kết', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// ================= LINK WALLET ACTION =================
  Future<void> _linkWallet() async {
    final walletProvider = context.read<WalletProvider>();
    final wallets = walletProvider.wallets;
    if (wallets.isEmpty) {
      AppSnackBar.warning(context, 'Chưa có ví nào, hãy tạo ví trước');
      return;
    }

    String? selectedWalletId = wallets.first.id;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Liên kết với ví'),
          content: DropdownButton<String>(
            value: selectedWalletId,
            isExpanded: true,
            items: wallets.map((w) => DropdownMenuItem(
              value: w.id,
              child: Text('${w.icon} ${w.name}'),
            )).toList(),
            onChanged: (v) => setDialogState(() => selectedWalletId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<BankProvider>().updateWalletLink(
                    widget.account.id,
                    selectedWalletId,
                  );
                  if (mounted) {
                    AppSnackBar.success(context, 'Đã liên kết ví thành công! Giao dịch tiếp theo sẽ tự cập nhật.');
                    context.read<BankProvider>().loadAccounts();
                    setState(() {});
                  }
                } catch (e) {
                  if (mounted) AppSnackBar.error(context, 'Lỗi: $e');
                }
              },
              child: const Text('Liên kết'),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TRANSACTION CARD =================
  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amountIn = double.tryParse(tx['amount_in']?.toString() ?? '0') ?? 0.0;
    final amountOut = double.tryParse(tx['amount_out']?.toString() ?? '0') ?? 0.0;
    final isIncome = amountIn > 0;
    final amount = isIncome ? amountIn : amountOut;
    final content = tx['transaction_content'] ?? '';
    final date = tx['transaction_date'] ?? '';
    final refNumber = tx['reference_number'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Iconsax.arrow_down : Iconsax.arrow_up,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.isNotEmpty ? content : 'Giao dịch #$refNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? "+" : "-"}${_currencyFormat.format(amount)} đ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Iconsax.document, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Giao dịch sẽ hiển thị khi có tiền vào/ra tài khoản',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
