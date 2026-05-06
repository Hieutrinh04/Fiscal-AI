import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart' as model;
import '../../utils/formatters.dart';
import '../../widgets/markdown_text.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  static const List<String> _periodLabels = ['Tuần', 'Tháng', 'Năm'];
  int selectedTab = 1;
  int _typeTab = 0;
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDay;

  // 3D tilt animations
  late final AnimationController _entryController;
  late final Animation<double> _entryAnim;

  // Pie chart rotation
  late final AnimationController _pieRotation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);

    _pieRotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _entryController.forward();
    _initData();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pieRotation.dispose();
    super.dispose();
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

    final categories = catProvider.categories;
    final latestInsight = aiProvider.insights.isNotEmpty
        ? aiProvider.insights.first.content
        : "Hãy theo dõi chi tiêu của bạn qua biểu đồ.";

    final selectedType = _typeTab == 0
        ? model.TransactionType.expense
        : model.TransactionType.income;

    final dailyTotalsMap = transProvider.dailyTotals(selectedType);
    final maxDaily = dailyTotalsMap.values.fold(0, (a, b) => a > b ? a : b);
    final categoryTotalsMap = transProvider.categoryTotals(selectedType);
    final totalForType = categoryTotalsMap.values.fold(0, (a, b) => a + b);
    final dayTransactions = _selectedDay == null
        ? <Transaction>[]
        : transProvider.transactionsForDay(_selectedDay!, selectedType);
    final typeCategories =
        categories.where((c) => c.type == selectedType).toList();

    final accentColor =
        _typeTab == 0 ? const Color(0xffEF4444) : const Color(0xff16A34A);

    final List<Map<String, dynamic>> spendingList =
        categoryTotalsMap.entries.map((e) {
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
            child: AnimatedBuilder(
              animation: _entryAnim,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _staggered(0, _buildTypeTab()),
                          const SizedBox(height: 14),
                          _staggered(
                              1,
                              _buildCalendarCard(
                                  dailyTotalsMap, maxDaily, accentColor)),
                          if (_selectedDay != null) ...[
                            const SizedBox(height: 14),
                            _staggered(
                                2,
                                _buildDayDetailCard(
                                    dayTransactions, accentColor)),
                          ],
                          const SizedBox(height: 18),
                          _staggered(
                              3,
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      icon: Iconsax.arrow_down_1,
                                      label: 'Tổng chi',
                                      amount: Formatters.currencyCompact(
                                          totalSpending.toDouble()),
                                      color: const Color(0xffEF4444),
                                      index: 0,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      icon: Iconsax.arrow_up_2,
                                      label: 'Tổng thu',
                                      amount: Formatters.currencyCompact(
                                          totalIncome.toDouble()),
                                      color: const Color(0xff16A34A),
                                      index: 1,
                                    ),
                                  ),
                                ],
                              )),
                          const SizedBox(height: 18),
                          _staggered(
                              4, _buildBarChartCard(selectedType, accentColor)),
                          const SizedBox(height: 18),
                          if (spendingList.isNotEmpty) ...[
                            _staggered(
                                5,
                                _buildDistributionCard(
                                    spendingList, totalForType, accentColor)),
                            const SizedBox(height: 18),
                          ],
                          _staggered(6, _buildAiInsightCard(latestInsight)),
                          const SizedBox(height: 18),
                          _staggered(
                              7,
                              Text(
                                _typeTab == 0
                                    ? 'Chi tiêu theo danh mục'
                                    : 'Thu nhập theo danh mục',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff1F2937),
                                ),
                              )),
                          const SizedBox(height: 12),
                          if (spendingList.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  _typeTab == 0
                                      ? "Chưa có dữ liệu chi tiêu"
                                      : "Chưa có dữ liệu thu nhập",
                                  style: GoogleFonts.inter(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ...List.generate(
                              spendingList.length,
                              (i) => _staggered(
                                  8 + i,
                                  _buildCategoryRow(
                                      spendingList[i], totalForType, i)),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Stagger fade-slide entry
  Widget _staggered(int index, Widget child) {
    final delay = (index * 0.08).clamp(0.0, 0.9);
    final start = delay;
    final end = (delay + 0.3).clamp(0.0, 1.0);
    final t = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: t,
      builder: (context, c) {
        return Opacity(
          opacity: t.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t.value)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  Color _getColorForCategory(String name) {
    final colors = [
      const Color(0xffE85D55),
      const Color(0xff3B82F6),
      const Color(0xffF59E0B),
      const Color(0xff22C55E),
      const Color(0xff8B5CF6),
      const Color(0xff06B6D4),
      const Color(0xffEC4899),
      const Color(0xff94A3B8),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  /// ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2F80ED).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.chart_21,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Thống kê',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(_periodLabels.length, (index) {
                final isActive = selectedTab == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _periodLabels[index],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? const Color(0xff2F80ED)
                                : Colors.white,
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

  /// ================= TYPE TAB =================
  Widget _buildTypeTab() {
    return Container(
      padding: const EdgeInsets.all(4),
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
          _typeTabBtn(0, 'Chi tiêu', const Color(0xffEF4444)),
          _typeTabBtn(1, 'Thu nhập', const Color(0xff16A34A)),
        ],
      ),
    );
  }

  Widget _typeTabBtn(int idx, String label, Color color) {
    final active = _typeTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _typeTab = idx;
          _selectedDay = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [color, color.withOpacity(0.75)])
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: active ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= CALENDAR CARD =================
  Widget _buildCalendarCard(
      Map<String, int> dailyTotals, int maxDaily, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _calNavBtn(Icons.chevron_left, () {
                setState(() => _calendarMonth = DateTime(
                    _calendarMonth.year, _calendarMonth.month - 1));
              }),
              Text(
                'Tháng ${_calendarMonth.month} / ${_calendarMonth.year}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xff1F2937),
                ),
              ),
              _calNavBtn(Icons.chevron_right, () {
                setState(() => _calendarMonth = DateTime(
                    _calendarMonth.year, _calendarMonth.month + 1));
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          _buildCalendarGrid(dailyTotals, maxDaily, accentColor),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xffF3F4F6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: const Color(0xff1F2937)),
        ),
      ),
    );
  }

  Widget _buildDayDetailCard(List<Transaction> dayTrans, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${dayTrans.length} giao dịch',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dayTrans.isEmpty)
            Text('Không có giao dịch',
                style: GoogleFonts.inter(
                    color: Colors.grey[400], fontSize: 13))
          else
            ...dayTrans.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(t.category?.icon ?? '💰',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.displayTitle,
                          style: GoogleFonts.inter(fontSize: 13.5),
                        ),
                      ),
                      Text(
                        '${_typeTab == 0 ? "-" : "+"}${Formatters.currency(t.amount.toDouble())}',
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  /// ================= SUMMARY CARD với 3D tilt =================
  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
    required int index,
  }) {
    return _Tilt3D(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 900 + index * 150),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Opacity(
                opacity: v,
                child: Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= BAR CHART CARD =================
  Widget _buildBarChartCard(model.TransactionType type, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_2, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                _typeTab == 0
                    ? 'Chi tiêu 6 tháng gần nhất'
                    : 'Thu nhập 6 tháng gần nhất',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: const Color(0xff1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBarChart(type, accentColor),
        ],
      ),
    );
  }

  /// ================= BAR CHART (6 tháng) với 3D =================
  Widget _buildBarChart(model.TransactionType type, Color accentColor) {
    final now = DateTime.now();
    final monthlyTotals =
        context.read<TransactionProvider>().monthlyTotals(type);
    final maxVal = monthlyTotals.values.fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthlyTotals.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final parts = item.key.split('-');
          final monthNum = int.parse(parts[1]);
          final ratio =
              maxVal > 0 ? (item.value / maxVal).clamp(0.0, 1.0) : 0.0;
          final isCurrent =
              item.key == '${now.year}-${now.month.toString().padLeft(2, '0')}';

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.value > 0)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800 + idx * 100),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => Opacity(
                        opacity: v,
                        child: Text(
                          Formatters.currencyCompact(item.value.toDouble()),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: Duration(milliseconds: 900 + idx * 120),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => _Bar3D(
                      height: (v * 110).clamp(4.0, 110.0),
                      color: accentColor,
                      isHighlight: isCurrent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'T$monthNum',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isCurrent ? accentColor : Colors.grey[500],
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
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

  /// ================= PIE DISTRIBUTION CARD với animation =================
  Widget _buildDistributionCard(
      List<Map<String, dynamic>> spending, int total, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_1, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                _typeTab == 0 ? 'Phân bổ chi tiêu' : 'Phân bổ thu nhập',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 3D tilted pie
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, __) {
                    return AnimatedBuilder(
                      animation: _pieRotation,
                      builder: (_, __) {
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateX(0.28)
                            ..rotateZ(_pieRotation.value * 2 * math.pi * 0.05),
                          child: Opacity(
                            opacity: t,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 52,
                                sectionsSpace: 3,
                                startDegreeOffset: -90,
                                sections: spending.map((item) {
                                  return PieChartSectionData(
                                    value:
                                        (item['value'] as int).toDouble() * t,
                                    color: item['color'] as Color,
                                    radius: 36 * t,
                                    showTitle: false,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _typeTab == 0 ? 'Tổng chi' : 'Tổng thu',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: total.toDouble()),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        Formatters.currencyCompact(v),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 10,
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
                      boxShadow: [
                        BoxShadow(
                          color: (item['color'] as Color).withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item['name']} ',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ================= AI INSIGHT =================
  Widget _buildAiInsightCard(String insight) {
    return _Tilt3D(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff667EEA), Color(0xff764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff667EEA).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.magic_star,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI phân tích tài chính',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownText(
              insight,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withOpacity(0.95),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= CATEGORY ROW với progress bar animated =================
  Widget _buildCategoryRow(Map<String, dynamic> item, int total, int index) {
    final value = item['value'] as int;
    final percent = total > 0 ? value / total : 0.0;
    final color = item['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    item['icon'] as String,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1F2937),
                  ),
                ),
              ),
              Text(
                Formatters.currency(value.toDouble()),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: Duration(milliseconds: 800 + index * 100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(
                children: [
                  Container(
                    height: 6,
                    color: color.withOpacity(0.12),
                  ),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(percent * 100).toStringAsFixed(1)}% tổng',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CALENDAR GRID =================
  Widget _buildCalendarGrid(
      Map<String, int> dailyTotals, int maxDaily, Color accentColor) {
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

      final intensity =
          maxDaily > 0 ? (amount / maxDaily).clamp(0.0, 1.0) : 0.0;
      Color cellBg;
      if (amount > 0) {
        cellBg = accentColor.withOpacity(0.1 + intensity * 0.5);
      } else {
        cellBg = Colors.transparent;
      }

      cells.add(
        GestureDetector(
          onTap: () =>
              setState(() => _selectedDay = isSelected ? null : date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 44,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [accentColor, accentColor.withOpacity(0.8)],
                    )
                  : null,
              color: isSelected ? null : cellBg,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected
                  ? Border.all(color: accentColor, width: 1.5)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight:
                          isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
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
                      style: GoogleFonts.inter(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : accentColor,
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
        children:
            cells.sublist(i, i + 7).map((c) => Expanded(child: c)).toList(),
      ));
    }

    return Column(children: rows);
  }
}

/// ================= 3D TILT WIDGET =================
/// Card nghiêng theo vị trí chạm (perspective transform)
class _Tilt3D extends StatefulWidget {
  final Widget child;
  const _Tilt3D({required this.child});

  @override
  State<_Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<_Tilt3D> {
  double _rotX = 0;
  double _rotY = 0;

  void _onHover(Offset local, Size size) {
    setState(() {
      final dx = (local.dx / size.width - 0.5) * 2; // -1..1
      final dy = (local.dy / size.height - 0.5) * 2;
      _rotY = dx * 0.12;
      _rotX = -dy * 0.12;
    });
  }

  void _reset() => setState(() {
        _rotX = 0;
        _rotY = 0;
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanUpdate: (d) => _onHover(d.localPosition, size),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          onTapDown: (d) => _onHover(d.localPosition, size),
          onTapUp: (_) => _reset(),
          onTapCancel: _reset,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(_rotX)
              ..rotateY(_rotY),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// ================= 3D BAR =================
/// Thanh với hiệu ứng 3D (mặt trên + gradient)
class _Bar3D extends StatelessWidget {
  final double height;
  final Color color;
  final bool isHighlight;

  const _Bar3D({
    required this.height,
    required this.color,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isHighlight ? color : color.withOpacity(0.55);
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Shadow bên dưới (depth)
        Positioned(
          bottom: -2,
          child: Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        // Bar chính với gradient 3D
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                baseColor,
                baseColor.withOpacity(isHighlight ? 0.75 : 0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
              bottom: Radius.circular(4),
            ),
            boxShadow: isHighlight
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
