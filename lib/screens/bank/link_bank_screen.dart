import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/bank_account.dart';
import '../../providers/bank_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/snackbar.dart';
import 'bank_transactions_screen.dart';

class LinkBankScreen extends StatefulWidget {
  final String? preselectedWalletId;
  const LinkBankScreen({super.key, this.preselectedWalletId});

  @override
  State<LinkBankScreen> createState() => _LinkBankScreenState();
}

class _LinkBankScreenState extends State<LinkBankScreen> {
  final _accountNumberController = TextEditingController();
  String? _selectedBankCode;
  String? _selectedBankName;
  String? _selectedWalletId;

  /// Trạng thái xác minh tự động
  String? _verifiedName;
  bool _isVerifying = false;
  String? _verifyError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    context.read<BankProvider>().loadAccounts();
    _accountNumberController.addListener(_onAccountNumberChanged);
    if (widget.preselectedWalletId != null) {
      _selectedWalletId = widget.preselectedWalletId;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _accountNumberController.removeListener(_onAccountNumberChanged);
    _accountNumberController.dispose();
    super.dispose();
  }

  void _onAccountNumberChanged() {
    setState(() {
      _verifiedName = null;
      _verifyError = null;
    });
    _debounceTimer?.cancel();
    final number = _accountNumberController.text.trim();
    if (number.length >= 6 && _selectedBankCode != null) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), _autoVerify);
    }
  }

  Future<void> _autoVerify() async {
    final number = _accountNumberController.text.trim();
    if (number.isEmpty || _selectedBankCode == null) return;

    setState(() {
      _isVerifying = true;
      _verifyError = null;
      _verifiedName = null;
    });

    try {
      final bankProvider = context.read<BankProvider>();
      final name = await bankProvider.verifyBankAccount(
        bankCode: _selectedBankCode!,
        accountNumber: number,
      );
      if (mounted) {
        setState(() {
          _verifiedName = name;
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifyError = e.toString().replaceAll('Exception: ', '');
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final wallets = context.watch<WalletProvider>().wallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liên kết ngân hàng'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= LINKED ACCOUNTS =================
            if (bank.accounts.isNotEmpty) ...[
              const Text(
                'Tài khoản đã liên kết',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...bank.accounts.map((account) => _buildAccountCard(account)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            /// ================= ADD NEW =================
            const Text(
              'Thêm tài khoản ngân hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            /// CHỌN NGÂN HÀNG
            DropdownButtonFormField<String>(
              value: _selectedBankCode,
              decoration: InputDecoration(
                labelText: 'Chọn ngân hàng',
                prefixIcon: const Icon(Iconsax.bank),
                filled: true,
                fillColor: const Color(0xffF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: BankAccount.vietnamBanks.map((b) {
                return DropdownMenuItem(
                  value: b['code'],
                  child: Text('${b['name']} (${b['code']})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBankCode = val;
                  _selectedBankName = BankAccount.vietnamBanks
                      .firstWhere((b) => b['code'] == val)['name'];
                });
              },
            ),
            const SizedBox(height: 12),

            /// SỐ TÀI KHOẢN
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tài khoản',
                prefixIcon: const Icon(Iconsax.card),
                filled: true,
                fillColor: const Color(0xffF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _isVerifying
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _verifiedName != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
              ),
            ),
            const SizedBox(height: 8),

            /// TÊN CHỦ TÀI KHOẢN (read-only, auto-filled)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _verifiedName != null
                  ? Container(
                      key: const ValueKey('verified'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.user_tick, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chủ tài khoản',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                                ),
                                Text(
                                  _verifiedName!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.lock, size: 16, color: Colors.green.shade400),
                        ],
                      ),
                    )
                  : _verifyError != null
                      ? Container(
                          key: const ValueKey('error'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _verifyError!,
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            const SizedBox(height: 12),

            /// LIÊN KẾT VỚI VÍ
            if (wallets.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                decoration: InputDecoration(
                  labelText: 'Liên kết với ví (tùy chọn)',
                  prefixIcon: const Icon(Iconsax.wallet),
                  filled: true,
                  fillColor: const Color(0xffF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Không liên kết'),
                  ),
                  ...wallets.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
            const SizedBox(height: 24),

            /// ERROR
            if (bank.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  bank.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: bank.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Iconsax.link),
                label: Text(bank.isLoading ? 'Đang xử lý...' : 'Liên kết tài khoản'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xff2F80ED),
                ),
                onPressed: bank.isLoading ? null : _handleLink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HANDLE LINK =================
  Future<void> _handleLink() async {
    if (_selectedBankCode == null) {
      AppSnackBar.warning(context, 'Vui lòng chọn ngân hàng');
      return;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      AppSnackBar.warning(context, 'Vui lòng nhập số tài khoản');
      return;
    }
    if (_verifiedName == null) {
      AppSnackBar.warning(context, 'Vui lòng chờ xác minh tài khoản');
      return;
    }

    final bankProvider = context.read<BankProvider>();

    final account = await bankProvider.linkManually(
      bankName: _selectedBankName!,
      bankCode: _selectedBankCode!,
      accountNumber: _accountNumberController.text.trim(),
      accountName: _verifiedName!,
      walletId: _selectedWalletId,
    );

    if (account != null && mounted) {
      AppSnackBar.success(
        context,
        'Liên kết thành công! Chủ TK: ${account.accountName}',
      );
      _accountNumberController.clear();
      setState(() {
        _selectedBankCode = null;
        _selectedBankName = null;
        _selectedWalletId = null;
        _verifiedName = null;
        _verifyError = null;
      });
    } else if (bankProvider.error != null && mounted) {
      AppSnackBar.error(context, bankProvider.error!);
    }
  }

  /// ================= ACCOUNT CARD =================
  Widget _buildAccountCard(BankAccount account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BankTransactionsScreen(account: account),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xff2F80ED).withValues(alpha: 0.1),
          child: const Icon(Iconsax.bank, color: Color(0xff2F80ED)),
        ),
        title: Text(
          '${account.bankName} - ${account.accountNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Flexible(child: Text(account.accountName)),
            if (account.isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 14, color: Colors.green),
            ],
            const SizedBox(width: 6),
            const Text('Xem GD ›', style: TextStyle(color: Color(0xff2F80ED), fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Iconsax.trash, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Xóa liên kết?'),
                content: const Text('Bạn có chắc muốn xóa liên kết ngân hàng này?'),
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
              await context.read<BankProvider>().deleteAccount(account.id);
              if (mounted) AppSnackBar.success(context, 'Đã xóa liên kết');
            }
          },
        ),
      ),
    );
  }
}
