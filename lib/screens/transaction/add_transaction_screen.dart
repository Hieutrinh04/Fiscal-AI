import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart' as model;
import '../../models/wallet.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool isExpense;
  late DateTime selectedDate;
  bool _isSubmitting = false;
  bool get _isEditing => widget.transaction != null;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String? selectedCategoryId;
  String? selectedWalletId;

  @override
  void initState() {
    super.initState();

    // Pre-fill nếu đang chỉnh sửa
    final t = widget.transaction;
    if (t != null) {
      isExpense = t.type == model.TransactionType.expense;
      selectedDate = t.date;
      amountController.text = t.amount.toString();
      descController.text = t.note ?? '';
      selectedCategoryId = t.categoryId;
      selectedWalletId = t.walletId;
    } else {
      isExpense = true;
      selectedDate = DateTime.now();
    }

    _initData();

    descController.addListener(() {
      _autoCategory(descController.text);
    });
  }

  Future<void> _initData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<WalletProvider>().loadWallets();
    });
  }

  void _autoCategory(String text) {
    if (text.isEmpty) return;
    final categories = context.read<CategoryProvider>().categories;
    final type = isExpense ? model.TransactionType.expense : model.TransactionType.income;

    final filteredCats = categories.where((c) => c.type == type).toList();
    if (filteredCats.isEmpty) return;

    final lowerText = text.toLowerCase();
    for (var cat in filteredCats) {
      if (lowerText.contains(cat.name.toLowerCase())) {
        setState(() => selectedCategoryId = cat.id);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final walletProvider = context.watch<WalletProvider>();

    final type = isExpense ? model.TransactionType.expense : model.TransactionType.income;
    final currentCategories = catProvider.categories.where((c) => c.type == type).toList();
    final wallets = walletProvider.wallets;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (wallets.isNotEmpty) {
        final exists = selectedWalletId != null && wallets.any((w) => w.id == selectedWalletId);
        if (!exists) {
          setState(() => selectedWalletId = wallets.first.id);
        }
      }

      if (currentCategories.isNotEmpty) {
        final exists = selectedCategoryId != null &&
            currentCategories.any((c) => c.id == selectedCategoryId);
        if (!exists) {
          setState(() => selectedCategoryId = currentCategories.first.id);
        }
      }
    });

    model.Category? selectedCategory;
    if (selectedCategoryId != null) {
      try {
        selectedCategory =
            currentCategories.firstWhere((c) => c.id == selectedCategoryId);
      } catch (_) {
        selectedCategory = null;
      }
    }

    Wallet? selectedWallet;
    if (selectedWalletId != null) {
      try {
        selectedWallet = wallets.firstWhere((w) => w.id == selectedWalletId);
      } catch (_) {
        selectedWallet = null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(_isEditing ? "Chỉnh sửa giao dịch" : "Thêm giao dịch", style: const TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= SWITCH =================
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpense = true;
                          selectedCategoryId = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isExpense ? Colors.red : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Chi tiêu",
                            style: TextStyle(
                              color: isExpense ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpense = false;
                          selectedCategoryId = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isExpense ? Colors.green : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Thu nhập",
                            style: TextStyle(
                              color: !isExpense ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ================= WALLET SELECT =================
            const Text("Chọn ví"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: wallets.any((w) => w.id == selectedWalletId) ? selectedWalletId : null,
                  isExpanded: true,
                  items: wallets
                      .map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedWalletId = val),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ================= AMOUNT =================
            const Text("Số tiền (₫)"),
            const SizedBox(height: 8),
            buildInput(amountController, "0", Iconsax.money, isNumber: true),

            const SizedBox(height: 16),

            /// ================= DESCRIPTION =================
            const Text("Mô tả (AI tự phân loại)"),
            const SizedBox(height: 8),
            buildInput(descController, "VD: ăn phở", Iconsax.note),

            const SizedBox(height: 6),

            if (selectedCategory != null)
              Text(
                "🤖 AI gợi ý: ${selectedCategory!.name}",
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),

            const SizedBox(height: 16),

            /// ================= DATE =================
            const Text("Ngày"),
            const SizedBox(height: 8),
            buildDate(),

            const SizedBox(height: 16),

            /// ================= CATEGORY =================
            const Text("Danh mục"),
            const SizedBox(height: 10),

            if (currentCategories.isEmpty)
              const Text("Đang tải danh mục...", style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: currentCategories.map((cat) {
                  final isSelected = selectedCategoryId == cat.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryId = cat.id;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                          ),
                          child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 5),
                        Text(cat.name, style: const TextStyle(fontSize: 12))
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 30),

            /// ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpense ? Colors.red : Colors.green,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  if (_isSubmitting) return;
                  final amount = int.tryParse(amountController.text) ?? 0;
                  if (amount <= 0 || selectedCategoryId == null || selectedWalletId == null) {
                    AppSnackBar.warning(context, 'Vui lòng điền đầy đủ thông tin');
                    return;
                  }

                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  final wallet = wallets.firstWhere(
                    (w) => w.id == selectedWalletId,
                    orElse: () => wallets.first,
                  );
                  final category = currentCategories.firstWhere(
                    (c) => c.id == selectedCategoryId,
                    orElse: () => currentCategories.first,
                  );

                  try {
                    setState(() => _isSubmitting = true);

                    if (_isEditing) {
                      // Cập nhật giao dịch
                      final updatedTransaction = widget.transaction!.copyWith(
                        walletId: wallet.id,
                        categoryId: category.id,
                        type: type,
                        amount: amount,
                        note: descController.text.trim(),
                        date: selectedDate,
                      );
                      await context.read<TransactionProvider>().updateTransaction(updatedTransaction);
                      if (!mounted) return;
                      await context.read<WalletProvider>().loadWallets();
                      if (!mounted) return;
                      AppSnackBar.success(context, 'Đã cập nhật giao dịch');
                    } else {
                      // Thêm mới
                      final newTransaction = Transaction(
                        id: '',
                        userId: user.id,
                        walletId: wallet.id,
                        categoryId: category.id,
                        type: type,
                        amount: amount,
                        note: descController.text.trim(),
                        date: selectedDate,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      await context.read<TransactionProvider>().addTransaction(newTransaction);
                      if (!mounted) return;
                      await context.read<WalletProvider>().loadWallets();
                      if (!mounted) return;
                      AppSnackBar.success(context, 'Đã thêm giao dịch');
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    AppSnackBar.error(context, 'Lỗi: $e');
                  } finally {
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                  }
                },
                child: Text(
                  _isEditing
                      ? (isExpense ? "Cập nhật chi tiêu" : "Cập nhật thu nhập")
                      : (isExpense ? "Thêm chi tiêu" : "Thêm thu nhập"),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= COMPONENT =================

  Widget buildInput(TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildDate() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
            const Icon(Iconsax.calendar),
          ],
        ),
      ),
    );
  }
}
