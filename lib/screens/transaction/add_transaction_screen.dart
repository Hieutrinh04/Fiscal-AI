import 'dart:async';
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
import '../../services/ai_service.dart';
import '../../utils/category_keywords.dart';
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
  String _formattedAmount = '';

  // AI suggestion state
  final AiService _aiService = AiService();
  Timer? _aiDebounce;
  bool _isSuggesting = false;
  String? _suggestionSource; // 'keyword' | 'ai' | null
  bool _userManuallyChose = false; // user đã tự chọn → không override nữa

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

    amountController.addListener(() {
      _formatAmount();
    });

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

  void _formatAmount() {
    final raw = amountController.text.replaceAll(',', '');
    final num = int.tryParse(raw);
    if (num != null && num > 0) {
      final formatted = _formatVND(num);
      if (_formattedAmount != formatted) {
        _formattedAmount = formatted;
      }
    } else {
      _formattedAmount = '';
    }
    setState(() {});
  }

  String _formatVND(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()}₫';
  }

  /// Gợi ý danh mục: 1) keyword local instant, 2) AI fallback debounced.
  /// User đã chủ động chọn rồi → không override.
  void _autoCategory(String text) {
    _aiDebounce?.cancel();

    if (text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _suggestionSource = null;
          _isSuggesting = false;
        });
      }
      return;
    }
    if (_userManuallyChose) return;

    final categories = context.read<CategoryProvider>().categories;
    final type = isExpense
        ? model.TransactionType.expense
        : model.TransactionType.income;
    final filteredCats = categories.where((c) => c.type == type).toList();
    if (filteredCats.isEmpty) return;

    // 1️⃣ KEYWORD MAP (instant)
    final suggestedNames = CategoryKeywords.suggest(text);
    if (suggestedNames.isNotEmpty) {
      for (final name in suggestedNames) {
        final normName = CategoryKeywords.normalize(name);
        final match = filteredCats.where((c) =>
            CategoryKeywords.normalize(c.name).contains(normName) ||
            normName.contains(CategoryKeywords.normalize(c.name)));
        if (match.isNotEmpty) {
          setState(() {
            selectedCategoryId = match.first.id;
            _suggestionSource = 'keyword';
            _isSuggesting = false;
          });
          return;
        }
      }
    }

    // 2️⃣ Match trực tiếp tên danh mục (fallback nhẹ)
    final normText = CategoryKeywords.normalize(text);
    for (final cat in filteredCats) {
      if (normText.contains(CategoryKeywords.normalize(cat.name))) {
        setState(() {
          selectedCategoryId = cat.id;
          _suggestionSource = 'keyword';
          _isSuggesting = false;
        });
        return;
      }
    }

    // 3️⃣ AI FALLBACK (debounce 800ms để tránh spam)
    _aiDebounce = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted || _userManuallyChose) return;
      if (text.trim().length < 3) return; // quá ngắn không đáng gọi AI

      setState(() => _isSuggesting = true);

      final catPayload = filteredCats
          .map((c) => {'id': c.id, 'name': c.name, 'icon': c.icon})
          .toList();

      final id = await _aiService.suggestCategory(
        note: text,
        categories: catPayload,
      );

      if (!mounted || _userManuallyChose) return;
      setState(() {
        _isSuggesting = false;
        if (id != null) {
          selectedCategoryId = id;
          _suggestionSource = 'ai';
        }
      });
    });
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    amountController.dispose();
    descController.dispose();
    super.dispose();
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
                          _userManuallyChose = false;
                          _suggestionSource = null;
                        });
                        _autoCategory(descController.text);
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
                          _userManuallyChose = false;
                          _suggestionSource = null;
                        });
                        _autoCategory(descController.text);
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
            if (_formattedAmount.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _formattedAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// ================= DESCRIPTION =================
            const Text("Mô tả (AI tự phân loại)"),
            const SizedBox(height: 8),
            buildInput(descController, "VD: ăn phở", Iconsax.note),

            const SizedBox(height: 6),

            // Suggestion hint
            if (_isSuggesting)
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI đang phân loại...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              )
            else if (selectedCategory != null && _suggestionSource != null && !_userManuallyChose)
              Row(
                children: [
                  Icon(
                    _suggestionSource == 'ai' ? Iconsax.magic_star : Iconsax.flash_1,
                    size: 12,
                    color: _suggestionSource == 'ai' ? const Color(0xff8B5CF6) : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _suggestionSource == 'ai'
                        ? 'AI gợi ý: ${selectedCategory.name}'
                        : 'Gợi ý: ${selectedCategory.name}',
                    style: TextStyle(
                      color: _suggestionSource == 'ai' ? const Color(0xff8B5CF6) : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                        _userManuallyChose = true;
                        _suggestionSource = null;
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
                  final amount = int.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
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
