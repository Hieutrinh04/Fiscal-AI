import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart' as model;
import '../../utils/formatters.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const List<String> _periodLabels = ['Tuần', 'Tháng', 'Năm'];
  int selectedTab = 1;
  int _typeTab = 0; // 0 = Chi tiêu, 1 = Thu nhập
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TransactionProvider>().loadTransactions();
        context.read<CategoryProvider>().loadCategories();
        context.read<AiProvider>().loadInsights(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transProvider = context.watch<TransactionProvider>();
    final aiProvider = context.watch<AiProvider>();
    final catProvider = context.watch<CategoryProvider>();

    final transactions = transProvider.transactions;
    final categories = catProvider.categories;
    final latestInsight = aiProvider.insights.isNotEmpty
        ? aiProvider.insights.first.content
        : "Hãy theo dõi chi tiêu của bạn qua biểu đồ.";

    final selectedType = _typeTab == 0
        ? model.TransactionType.expense
        : model.TransactionType.income;
    final typeTransactions =
        transactions.where((t) => t.type == selectedType).toList();
    final typeCategories =
        categories.where((c) => c.type == selectedType).toList();

    // Calendar data
    final Map<String, int> dailyTotals = {};
    for (final t in typeTransactions) {
      final key =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + t.amount;
    }
    final maxDaily = dailyTotals.values.fold(0, (a, b) => a > b ? a : b);

    // Category breakdown
    final Map<String, int> categoryTotals = {};
    for (final t in typeTransactions) {
      final catId = t.categoryId ?? 'other';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + t.amount;
    }
    final totalForType = categoryTotals.values.fold(0, (a, b) => a + b);

    // Day transactions
    final dayTransactions = _selectedDay == null
        ? <Transaction>[]
        : typeTransactions.where((t) {
            return t.date.year == _selectedDay!.year &&
                t.date.month == _selectedDay!.month &&
                t.date.day == _selectedDay!.day;
          }).toList();

    final accentColor =
        _typeTab == 0 ? const Color(0xffEF4444) : const Color(0xff16A34A);

    // Pie chart data
    final List<Map<String, dynamic>> spendingList = categoryTotals.entries.map((e) {
      final cat = typeCategories.firstWhere(
        (c) => c.id == e.key,
        orElse: () => model.Category(
          id: 'other',
          name: 'Khác',
          icon: '📦',
          color: '#9CA3AF',
          type: selectedType,
          createdAt: DateTime.now(),
        ),
      );
      return {
        'name': cat.name,
        'icon': cat.icon,
        'value': e.value,
        'color': _getColorForCategory(cat.name),
      };
    }).toList()
      ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

    final totalSpending = transProvider.totalExpense;
    final totalIncome = transProvider.totalIncome;

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _initData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TYPE TAB CHI / THU
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
                                  _typeTab = 0;
                                  _selectedDay = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _typeTab == 0
                                        ? const Color(0xffEF4444)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Chi tiêu',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _typeTab == 0 ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _typeTab = 1;
                                  _selectedDay = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _typeTab == 1
                                        ? const Color(0xff16A34A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Thu nhập',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _typeTab == 1 ? Colors.white : Colors.black54,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => setState(() =>
                                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1)),
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                ),
                                Text(
                                  'Tháng ${_calendarMonth.month} / ${_calendarMonth.year}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                IconButton(
                                  onPressed: () => setState(() =>
                                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1)),
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                            _buildCalendarGrid(dailyTotals, maxDaily, accentColor),
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
                                            '${_typeTab == 0 ? "-" : "+"}${Formatters.currency(t.amount.toDouble())}',
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
                            child: _buildSummaryCard(
                              icon: Iconsax.arrow_down_1,
                              label: 'Tổng chi',
                              amount: Formatters.currencyCompact(totalSpending.toDouble()),
                              color: const Color(0xffE85D55),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              icon: Iconsax.arrow_up_2,
                              label: 'Tổng thu',
                              amount: Formatters.currencyCompact(totalIncome.toDouble()),
                              color: const Color(0xff16A34A),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// BAR CHART 6 tháng
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
                              _typeTab == 0 ? 'Chi tiêu 6 tháng gần nhất' : 'Thu nhập 6 tháng gần nhất',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            _buildBarChart(typeTransactions, accentColor),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// PIE CHART
                      if (spendingList.isNotEmpty) ...[
                        _buildDistributionCard(spendingList, totalForType, accentColor),
                        const SizedBox(height: 16),
                      ],

                      /// AI INSIGHT
                      _buildAiInsightCard(latestInsight),
                      const SizedBox(height: 16),

                      /// CATEGORY BREAKDOWN
                      Text(
                        _typeTab == 0 ? 'Chi tiêu theo danh mục' : 'Thu nhập theo danh mục',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (spendingList.isEmpty)
                        Center(
                            child: Text(
                                _typeTab == 0 ? "Chưa có dữ liệu chi tiêu" : "Chưa có dữ liệu thu nhập",
                                style: const TextStyle(color: Colors.grey)))
                      else
                        ...spendingList.map(_buildCategoryRow),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForCategory(String name) {
    final colors = [
      const Color(0xffE85D55),
      const Color(0xff3B82F6),
      const Color(0xffF59E0B),
      const Color(0xff22C55E),
      const Color(0xff8B5CF6),
      const Color(0xff94A3B8),
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xffEEF2F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(_periodLabels.length, (index) {
                final isActive = selectedTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _periodLabels[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(List<Map<String, dynamic>> spending, int total, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _typeTab == 0 ? 'Phân bổ chi tiêu' : 'Phân bổ thu nhập',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 56,
                    sectionsSpace: 3,
                    sections: spending
                        .map(
                          (item) => PieChartSectionData(
                            value: (item['value'] as int).toDouble(),
                            color: item['color'] as Color,
                            radius: 32,
                            showTitle: false,
                          ),
                        )
                        .toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _typeTab == 0 ? 'Tổng chi' : 'Tổng thu',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      Formatters.currencyCompact(total.toDouble()),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: spending.map((item) {
              final percent =
                  (total > 0 ? (item['value'] as int) / total * 100 : 0)
                      .toStringAsFixed(0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item['name']} ',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(String insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.magic_star, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'AI phân tích chi tiêu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['name'] as String,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            Formatters.currency((item['value'] as int).toDouble()),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ================= BAR CHART (6 tháng) =================
  Widget _buildBarChart(List<Transaction> typeTransactions, Color accentColor) {
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
                    height: height * 0.9,
                    decoration: BoxDecoration(
                      color: isCurrentMonth ? accentColor : accentColor.withOpacity(0.3),
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
  Widget _buildCalendarGrid(Map<String, int> dailyTotals, int maxDaily, Color accentColor) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDay = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1);
    final totalDays = lastDay.day;

    List<Widget> cells = [];

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

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

      final intensity = maxDaily > 0 ? (amount / maxDaily).clamp(0.0, 1.0) : 0.0;
      Color cellBg;
      if (amount > 0) {
        cellBg = accentColor.withOpacity(0.1 + intensity * 0.5);
      } else {
        cellBg = Colors.transparent;
      }

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = isSelected ? null : date),
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
                        color: isSelected ? Colors.white70 : accentColor,
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

    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

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
}
