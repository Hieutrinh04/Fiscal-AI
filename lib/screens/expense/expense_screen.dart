import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart' as model;
import '../../utils/formatters.dart';
import '../../utils/snackbar.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  String? selectedCategoryId;
  bool _isSubmitting = false;
  int _selectedTab = 0; // 0 = Chi tiêu, 1 = Thu nhập
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();

    final categories = catProvider.categories;
    final transactions = transProvider.transactions;

    final selectedType = _selectedTab == 0
        ? model.TransactionType.expense
        : model.TransactionType.income;

    final typeTransactions =
        transactions.where((t) => t.type == selectedType).toList();
    final filteredList = selectedCategoryId == null
        ? typeTransactions
        : typeTransactions.where((t) => t.categoryId == selectedCategoryId).toList();

    final typeCategories =
        categories.where((c) => c.type == selectedType).toList();

    // Calendar data: map date -> total amount for selected type
    final Map<String, int> dailyTotals = {};
    for (final t in typeTransactions) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + t.amount;
    }
    final maxDaily = dailyTotals.values.fold(0, (a, b) => a > b ? a : b);

    // Category breakdown for selected type
    final Map<String, int> categoryTotals = {};
    for (final t in typeTransactions) {
      final catId = t.categoryId ?? 'other';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + t.amount;
    }
    final totalForType = categoryTotals.values.fold(0, (a, b) => a + b);

    // Transactions for selected day
    final dayTransactions = _selectedDay == null
        ? <Transaction>[]
        : typeTransactions.where((t) {
            return t.date.year == _selectedDay!.year &&
                t.date.month == _selectedDay!.month &&
                t.date.day == _selectedDay!.day;
          }).toList();

    final accentColor =
        _selectedTab == 0 ? const Color(0xffEF4444) : const Color(0xff16A34A);
    final accentBg =
        _selectedTab == 0 ? Colors.red.shade50 : Colors.green.shade50;

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: const Text("Thống kê"),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _initData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TAB CHI / THU
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedTab = 0;
                          selectedCategoryId = null;
                          _selectedDay = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? const Color(0xffEF4444)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Chi tiêu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedTab = 1;
                          selectedCategoryId = null;
                          _selectedDay = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? const Color(0xff16A34A)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Thu nhập',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// CALENDAR
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    /// Month navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () =>
                              setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1)),
                          icon: const Icon(Icons.chevron_left, size: 20),
                        ),
                        Text(
                          'Tháng ${_calendarMonth.month} / ${_calendarMonth.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1)),
                          icon: const Icon(Icons.chevron_right, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    /// Day headers
                    Row(
                      children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(d,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[400])),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),

                    /// Calendar grid
                    _buildCalendarGrid(dailyTotals, maxDaily, accentColor, accentBg),
                  ],
                ),
              ),

              /// Selected day detail
              if (_selectedDay != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${dayTransactions.length} giao dịch',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (dayTransactions.isEmpty)
                        Text('Không có giao dịch',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13))
                      else
                        ...dayTransactions.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text(t.category?.icon ?? '💰',
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.note ?? t.category?.name ?? 'Giao dịch',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${_selectedTab == 0 ? "-" : "+"}${Formatters.currency(t.amount.toDouble())}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              /// SUMMARY
              Row(
                children: [
                  Expanded(
                    child: summaryCard(
                        "Chi tiêu",
                        Formatters.currency(transProvider.totalExpense.toDouble()),
                        Colors.red.shade100,
                        Colors.red),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: summaryCard(
                        "Thu nhập",
                        Formatters.currency(transProvider.totalIncome.toDouble()),
                        Colors.green.shade100,
                        Colors.green),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// BAR CHART - 6 tháng gần nhất
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTab == 0 ? 'Chi tiêu 6 tháng gần nhất' : 'Thu nhập 6 tháng gần nhất',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _buildBarChart(typeTransactions, accentColor),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// CATEGORY BREAKDOWN
              Text(
                _selectedTab == 0 ? 'Phân bổ chi tiêu' : 'Phân bổ thu nhập',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),

              if (categoryTotals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _selectedTab == 0
                          ? 'Chưa có chi tiêu nào'
                          : 'Chưa có thu nhập nào',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                )
              else
                ...(() {
                  final entries = categoryTotals.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return entries.map((entry) {
                  final cat = typeCategories.firstWhere(
                    (c) => c.id == entry.key,
                    orElse: () => model.Category(
                      id: 'other',
                      name: 'Khác',
                      icon: '📦',
                      color: '#9CA3AF',
                      type: selectedType,
                      createdAt: DateTime.now(),
                    ),
                  );
                  final pct = totalForType > 0
                      ? (entry.value / totalForType * 100)
                      : 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pct.toStringAsFixed(1)}% · ${Formatters.currency(entry.value.toDouble())}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(accentColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
                })(),

              const SizedBox(height: 20),

              /// FILTER
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => selectedCategoryId = null),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedCategoryId == null
                              ? const Color(0xff2F80ED)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Tất cả",
                          style: TextStyle(
                            color: selectedCategoryId == null
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    ...typeCategories.map((cat) {
                      final isActive = selectedCategoryId == cat.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = cat.id;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xff2F80ED)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// LIST
              Text("Giao dịch (${filteredList.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              if (filteredList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("Chưa có giao dịch nào",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Column(
                  children: filteredList.map((t) {
                    final isIncome = t.type == model.TransactionType.income;

                    return GestureDetector(
                      onLongPress: () {
                        _showMenu(context, t);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(t.category?.icon ?? "💰",
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.note ?? t.category?.name ?? "Giao dịch",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    "${Formatters.dateShort(t.date)} - ${t.category?.name ?? 'Khác'}",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isIncome ? "+" : "-"}${Formatters.currency(t.amount.toDouble())}",
                              style: TextStyle(
                                color: isIncome
                                    ? const Color(0xff16A34A)
                                    : const Color(0xffEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= BAR CHART (6 tháng) =================
  Widget _buildBarChart(List<Transaction> typeTransactions, Color accentColor) {
    // Calculate last 6 months totals
    final now = DateTime.now();
    final Map<String, int> monthlyTotals = {};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      monthlyTotals[key] = 0;
    }
    for (final t in typeTransactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      if (monthlyTotals.containsKey(key)) {
        monthlyTotals[key] = monthlyTotals[key]! + t.amount;
      }
    }
    final maxVal = monthlyTotals.values.fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthlyTotals.entries.map((entry) {
          final parts = entry.key.split('-');
          final monthNum = int.parse(parts[1]);
          final height = maxVal > 0 ? (entry.value / maxVal * 100) : 0.0;
          final isCurrentMonth = entry.key == '${now.year}-${now.month.toString().padLeft(2, '0')}';

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (entry.value > 0)
                    Text(
                      Formatters.currencyCompact(entry.value.toDouble()),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: height * 0.9, // max ~90px
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? accentColor
                          : accentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'T$monthNum',
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentMonth ? accentColor : Colors.grey[500],
                      fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ================= CALENDAR GRID =================
  Widget _buildCalendarGrid(
    Map<String, int> dailyTotals,
    int maxDaily,
    Color accentColor,
    Color accentBg,
  ) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDay = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    // Monday = 1, Sunday = 7 → shift to 0-based
    final startWeekday = (firstDay.weekday - 1); // 0=Mon, 6=Sun
    final totalDays = lastDay.day;

    List<Widget> cells = [];

    // Empty cells before first day
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final amount = dailyTotals[key] ?? 0;
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      // Intensity: 0 = no spending, 1 = max spending
      final intensity = maxDaily > 0 ? (amount / maxDaily).clamp(0.0, 1.0) : 0.0;

      Color cellBg;
      if (amount > 0) {
        cellBg = accentColor.withOpacity(0.1 + intensity * 0.5);
      } else {
        cellBg = Colors.transparent;
      }

      cells.add(
        GestureDetector(
          onTap: () => setState(() {
            _selectedDay = isSelected ? null : date;
          }),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : cellBg,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: accentColor, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? accentColor
                              : amount > 0
                                  ? Colors.black87
                                  : Colors.black38,
                    ),
                  ),
                  if (amount > 0)
                    Text(
                      Formatters.currencyCompact(amount.toDouble()),
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white70
                            : accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Pad to complete last row
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

    // Build rows
    List<Widget> rows = [];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: cells.sublist(i, i + 7).map((c) => Expanded(child: c)).toList(),
      ));
      if (i + 7 < cells.length) {
        rows.add(const SizedBox(height: 4));
      }
    }

    return Column(children: rows);
  }

  /// 🔥 MENU
  void _showMenu(BuildContext context, Transaction t) {
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
              const Text("Tùy chọn", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Iconsax.edit),
                title: const Text("Chỉnh sửa"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSheet(context, t);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: const Text("Xóa"),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteTransaction(context, t);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteTransaction(BuildContext context, Transaction t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá giao dịch'),
        content: Text('Bạn có chắc muốn xoá "${t.note ?? t.category?.name ?? 'Giao dịch'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<TransactionProvider>().deleteTransaction(t.id);
      if (!mounted) return;
      await context.read<WalletProvider>().loadWallets();
      if (!mounted) return;
      AppSnackBar.success(context, 'Đã xoá giao dịch');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Lỗi: $e');
    }
  }

  void _showEditSheet(BuildContext context, Transaction t) {
    final noteCtrl = TextEditingController(text: t.note ?? '');
    final amountCtrl = TextEditingController(text: t.amount.toString());
    DateTime selectedDate = t.date;
    model.TransactionType selectedType = t.type;
    String? categoryId = t.categoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final categories = context
              .read<CategoryProvider>()
              .categories
              .where((c) => c.type == selectedType)
              .toList();
          if (categoryId != null && !categories.any((c) => c.id == categoryId)) {
            categoryId = categories.isNotEmpty ? categories.first.id : null;
          }
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
                    const Text('Chỉnh sửa giao dịch',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Loại'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Thu nhập'),
                        selected: selectedType == model.TransactionType.income,
                        selectedColor: Colors.green.shade100,
                        onSelected: (v) {
                          if (!v) return;
                          setModalState(() => selectedType = model.TransactionType.income);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Chi tiêu'),
                        selected: selectedType == model.TransactionType.expense,
                        selectedColor: Colors.red.shade100,
                        onSelected: (v) {
                          if (!v) return;
                          setModalState(() => selectedType = model.TransactionType.expense);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Danh mục'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: categoryId,
                      isExpanded: true,
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.icon} ${c.name}'),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => categoryId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Số tiền (₫)'),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Ghi chú'),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Ngày'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Formatters.dateShort(selectedDate)),
                        const Icon(Iconsax.calendar, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final amount = int.tryParse(
                                  amountCtrl.text.replaceAll(',', '').replaceAll('.', ''),
                                ) ??
                                0;
                            if (amount <= 0 || categoryId == null) return;
                            try {
                              setState(() => _isSubmitting = true);
                              await context.read<TransactionProvider>().updateTransaction(
                                    t.copyWith(
                                      amount: amount,
                                      note: noteCtrl.text.trim(),
                                      type: selectedType,
                                      categoryId: categoryId,
                                      date: selectedDate,
                                    ),
                                  );
                              if (!mounted) return;
                              await context.read<WalletProvider>().loadWallets();
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              AppSnackBar.success(context, 'Đã cập nhật giao dịch');
                            } catch (e) {
                              if (!mounted) return;
                              AppSnackBar.error(context, 'Lỗi: $e');
                            } finally {
                              if (mounted) setState(() => _isSubmitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2F80ED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Lưu thay đổi',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget summaryCard(String title, String amount, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(amount,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

/// QUICK ITEM
class QuickItem extends StatelessWidget {
  final String icon;
  final String text;

  const QuickItem(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// 🔥 CLICK → ADD TRANSACTION
      onTap: () {
        Navigator.pushNamed(context, '/add-transaction');
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 5),
          Text(text, style: const TextStyle(fontSize: 11))
        ],
      ),
    );
  }
}
