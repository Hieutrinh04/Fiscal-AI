import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/goal_provider.dart';
import 'formatters.dart';
import 'spending_analyzer.dart';

/// Builds a comprehensive financial context string for the AI to ground
/// suggestions in the user's actual data (wallets, income, expenses, goals).
class AiContextBuilder {
  /// Reads all relevant providers from `context` and returns a multi-section
  /// summary string. Call this RIGHT BEFORE asking the AI for advice / chat,
  /// so the snapshot reflects the latest data.
  static String build(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final transProvider = context.read<TransactionProvider>();
    final goalProvider = context.read<GoalProvider>();

    final wallets = walletProvider.wallets;
    final allTx = transProvider.transactions;
    final goals = goalProvider.goals;

    final totalBalance = walletProvider.totalBalance;
    final totalIncome = transProvider.totalIncome;
    final totalExpense = transProvider.totalExpense;
    final netSaving = totalIncome - totalExpense;
    final savingRate = totalIncome > 0
        ? ((netSaving / totalIncome) * 100).clamp(-999, 100).toStringAsFixed(1)
        : '0';

    // ----- Wallets -----
    final walletsInfo = wallets.isEmpty
        ? '- (chưa có ví nào)'
        : wallets
            .map((w) =>
                '- ${w.name}: ${Formatters.currency(w.balance.toDouble())}')
            .join('\n');

    // ----- Expense breakdown by category -----
    final expenseByCat = <String, int>{};
    for (final t in allTx) {
      if (t.type != TransactionType.expense) continue;
      final name = t.category?.name ?? 'Khác';
      expenseByCat[name] = (expenseByCat[name] ?? 0) + t.amount;
    }
    final topExpenseCats = expenseByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final expenseBreakdown = topExpenseCats.isEmpty
        ? '- (chưa có chi tiêu)'
        : topExpenseCats
            .take(8)
            .map((e) =>
                '- ${e.key}: ${Formatters.currency(e.value.toDouble())}')
            .join('\n');

    // ----- Income breakdown by category -----
    final incomeByCat = <String, int>{};
    for (final t in allTx) {
      if (t.type != TransactionType.income) continue;
      final name = t.category?.name ?? 'Khác';
      incomeByCat[name] = (incomeByCat[name] ?? 0) + t.amount;
    }
    final topIncomeCats = incomeByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final incomeBreakdown = topIncomeCats.isEmpty
        ? '- (chưa có thu nhập)'
        : topIncomeCats
            .take(5)
            .map((e) =>
                '- ${e.key}: ${Formatters.currency(e.value.toDouble())}')
            .join('\n');

    // ----- Recent transactions (last 8 of each type) -----
    final recentExpenses = allTx
        .where((t) => t.type == TransactionType.expense)
        .take(8)
        .map((t) =>
            '- ${t.displayTitle}: ${Formatters.currency(t.amount.toDouble())} (${Formatters.date(t.date)})')
        .join('\n');

    final recentIncomes = allTx
        .where((t) => t.type == TransactionType.income)
        .take(5)
        .map((t) =>
            '- ${t.displayTitle}: ${Formatters.currency(t.amount.toDouble())} (${Formatters.date(t.date)})')
        .join('\n');

    // ----- Goals -----
    final goalsInfo = goals.isEmpty
        ? '- (chưa có mục tiêu)'
        : goals.map((g) {
            final pct = (g.progress * 100).toStringAsFixed(0);
            final deadline = g.deadline != null
                ? ', hạn: ${Formatters.date(g.deadline!)}'
                : '';
            return '- ${g.name}: ${Formatters.currency(g.currentAmount.toDouble())} / ${Formatters.currency(g.targetAmount.toDouble())} ($pct%$deadline)';
          }).join('\n');

    return '''
TỔNG QUAN TÀI CHÍNH
- Tổng số dư: ${Formatters.currency(totalBalance.toDouble())}
- Tổng thu nhập: ${Formatters.currency(totalIncome.toDouble())}
- Tổng chi tiêu: ${Formatters.currency(totalExpense.toDouble())}
- Chênh lệch (tiết kiệm): ${Formatters.currency(netSaving.toDouble())}
- Tỉ lệ tiết kiệm: $savingRate%

DANH SÁCH VÍ
$walletsInfo

CHI TIÊU THEO DANH MỤC (cao → thấp)
$expenseBreakdown

THU NHẬP THEO NGUỒN
$incomeBreakdown

CHI TIÊU GẦN ĐÂY
${recentExpenses.isEmpty ? '- (chưa có)' : recentExpenses}

THU NHẬP GẦN ĐÂY
${recentIncomes.isEmpty ? '- (chưa có)' : recentIncomes}

MỤC TIÊU TÀI CHÍNH
$goalsInfo
''';
  }

  // ==========================================================================
  // PER-SCREEN CONTEXT BUILDERS
  // Mỗi màn có snapshot riêng — ngắn gọn hơn, tập trung vào dữ liệu liên quan.
  // ==========================================================================

  /// Home: tổng quan + so sánh tốc độ chi tháng này với 3 tháng trước.
  static String buildForHome(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final transProvider = context.read<TransactionProvider>();
    final goalProvider = context.read<GoalProvider>();

    final allTx = transProvider.transactions;
    final pace = SpendingAnalyzer.paceForecast(allTx);
    final saving = SpendingAnalyzer.savingRateTrend(allTx);
    final anomalies = SpendingAnalyzer.detectCategoryAnomalies(allTx)
        .where((a) => a.isAnomaly)
        .take(3)
        .toList();

    final walletsLine = walletProvider.wallets.isEmpty
        ? '(chưa có ví)'
        : walletProvider.wallets
            .map((w) => '${w.name}=${Formatters.currency(w.balance.toDouble())}')
            .join(', ');

    final goalsLine = goalProvider.goals.isEmpty
        ? '(chưa có mục tiêu)'
        : goalProvider.goals
            .take(3)
            .map((g) =>
                '${g.name} ${(g.progress * 100).toStringAsFixed(0)}%')
            .join(', ');

    final anomaliesBlock = anomalies.isEmpty
        ? '- Không có danh mục bất thường'
        : anomalies
            .map((a) =>
                '- ${a.categoryName}: tháng này ${Formatters.currency(a.currentAmount.toDouble())}, trung bình ${Formatters.currency(a.meanAmount)} (z=${a.zScore.toStringAsFixed(1)})')
            .join('\n');

    return '''
TỔNG QUAN (Home)
- Tổng số dư: ${Formatters.currency(walletProvider.totalBalance.toDouble())}
- Ví: $walletsLine

TỐC ĐỘ CHI THÁNG NÀY
- Đã chi: ${Formatters.currency(pace.currentMonthSpent.toDouble())} (ngày ${pace.daysPassed}/${pace.daysInMonth})
- Dự báo cuối tháng: ${Formatters.currency(pace.forecastEndOfMonth.toDouble())}
- Trung vị 3 tháng trước: ${Formatters.currency(pace.baselineMedian.toDouble())}
- Tỉ số dự báo/trung vị: ${pace.ratio.toStringAsFixed(2)}× (${pace.severity})

TỈ LỆ TIẾT KIỆM
- Tháng này: ${(saving.currentRate * 100).toStringAsFixed(1)}%
- Trung bình 3 tháng trước: ${(saving.avgRate3m * 100).toStringAsFixed(1)}%
- Thay đổi: ${(saving.delta * 100).toStringAsFixed(1)} điểm%

DANH MỤC CHI BẤT THƯỜNG
$anomaliesBlock

MỤC TIÊU: $goalsLine
''';
  }

  /// Wallet: phân bổ ví + tốc độ "chảy máu" mỗi ví 30 ngày qua.
  static String buildForWallet(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    final transProvider = context.read<TransactionProvider>();

    final wallets = walletProvider.wallets;
    final allTx = transProvider.transactions;
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));

    // Chi 30 ngày qua mỗi ví
    final expense30dByWallet = <String, int>{};
    final income30dByWallet = <String, int>{};
    for (final t in allTx) {
      if (t.date.isBefore(since)) continue;
      if (t.type == TransactionType.expense) {
        expense30dByWallet[t.walletId] =
            (expense30dByWallet[t.walletId] ?? 0) + t.amount;
      } else if (t.type == TransactionType.income) {
        income30dByWallet[t.walletId] =
            (income30dByWallet[t.walletId] ?? 0) + t.amount;
      }
    }

    final walletsBlock = wallets.isEmpty
        ? '(chưa có ví)'
        : wallets.map((w) {
            final exp = expense30dByWallet[w.id] ?? 0;
            final inc = income30dByWallet[w.id] ?? 0;
            final net = inc - exp;
            return '- ${w.name}: số dư ${Formatters.currency(w.balance.toDouble())}, '
                '30d thu ${Formatters.currency(inc.toDouble())}, '
                'chi ${Formatters.currency(exp.toDouble())}, '
                'net ${Formatters.currency(net.toDouble())}';
          }).join('\n');

    return '''
PHÂN BỔ VÍ
- Tổng số dư tất cả ví: ${Formatters.currency(walletProvider.totalBalance.toDouble())}
- Số lượng ví: ${wallets.length}

CHI TIẾT TỪNG VÍ (30 ngày gần nhất)
$walletsBlock
''';
  }

  /// Statistic: xu hướng 6 tháng + breakdown danh mục + outliers.
  static String buildForStatistic(BuildContext context) {
    final transProvider = context.read<TransactionProvider>();
    final allTx = transProvider.transactions;

    // Monthly totals 6 tháng
    final monthlyExpense =
        transProvider.monthlyTotals(TransactionType.expense, months: 6);
    final monthlyIncome =
        transProvider.monthlyTotals(TransactionType.income, months: 6);

    final monthlyBlock = monthlyExpense.keys.map((k) {
      final exp = monthlyExpense[k] ?? 0;
      final inc = monthlyIncome[k] ?? 0;
      final net = inc - exp;
      return '- $k: thu ${Formatters.currency(inc.toDouble())}, chi ${Formatters.currency(exp.toDouble())}, net ${Formatters.currency(net.toDouble())}';
    }).join('\n');

    // Top danh mục chi tháng này
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final expenseByCat = <String, int>{};
    final catMeta = <String, Category>{};
    for (final t in allTx) {
      if (t.type != TransactionType.expense) continue;
      if (t.date.isBefore(startMonth)) continue;
      final cat = t.category;
      final id = cat?.id ?? 'other';
      if (cat != null) catMeta[id] = cat;
      expenseByCat[id] = (expenseByCat[id] ?? 0) + t.amount;
    }
    final sortedCats = expenseByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCatsBlock = sortedCats.isEmpty
        ? '(chưa có dữ liệu tháng này)'
        : sortedCats
            .take(8)
            .map((e) {
              final name = catMeta[e.key]?.name ?? 'Khác';
              return '- $name: ${Formatters.currency(e.value.toDouble())}';
            })
            .join('\n');

    // Anomalies
    final anomalies =
        SpendingAnalyzer.detectCategoryAnomalies(allTx, monthsLookback: 3)
            .where((a) => a.isAnomaly)
            .take(5)
            .toList();
    final anomaliesBlock = anomalies.isEmpty
        ? '- Không phát hiện bất thường'
        : anomalies
            .map((a) =>
                '- ${a.categoryName}: hiện ${Formatters.currency(a.currentAmount.toDouble())} vs TB ${Formatters.currency(a.meanAmount)} (z=${a.zScore.toStringAsFixed(1)})')
            .join('\n');

    return '''
XU HƯỚNG 6 THÁNG GẦN NHẤT
$monthlyBlock

TOP DANH MỤC CHI THÁNG NÀY
$topCatsBlock

BẤT THƯỜNG PHÁT HIỆN ĐƯỢC
$anomaliesBlock
''';
  }

  /// Goal: mục tiêu + khả năng đạt với tốc độ tiết kiệm hiện tại.
  static String buildForGoal(BuildContext context) {
    final goalProvider = context.read<GoalProvider>();
    final transProvider = context.read<TransactionProvider>();
    final allTx = transProvider.transactions;

    final goals = goalProvider.goals;
    final saving = SpendingAnalyzer.savingRateTrend(allTx);

    // Ước tính saving trung bình (VND) mỗi tháng dựa trên 3 tháng gần nhất
    final now = DateTime.now();
    final pastMonthsSaving = <int>[];
    for (int i = 1; i <= 3; i++) {
      final start = DateTime(now.year, now.month - i, 1);
      final end = DateTime(now.year, now.month - i + 1, 1);
      int inc = 0, exp = 0;
      for (final t in allTx) {
        if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
        if (t.type == TransactionType.income) inc += t.amount;
        if (t.type == TransactionType.expense) exp += t.amount;
      }
      pastMonthsSaving.add(inc - exp);
    }
    final avgMonthlySaving = pastMonthsSaving.isEmpty
        ? 0
        : pastMonthsSaving.reduce((a, b) => a + b) ~/ pastMonthsSaving.length;

    final goalsBlock = goals.isEmpty
        ? '(chưa có mục tiêu)'
        : goals.map((g) {
            final remain = g.targetAmount - g.currentAmount;
            final monthsNeeded = avgMonthlySaving > 0
                ? (remain / avgMonthlySaving).ceil()
                : null;
            final eta = monthsNeeded != null
                ? 'ước tính $monthsNeeded tháng nữa'
                : 'chưa đủ dữ liệu để ước tính';
            final deadline = g.deadline != null
                ? ', hạn ${Formatters.date(g.deadline!)}'
                : '';
            return '- ${g.name}: ${Formatters.currency(g.currentAmount.toDouble())}/${Formatters.currency(g.targetAmount.toDouble())} (${(g.progress * 100).toStringAsFixed(0)}%$deadline) — $eta';
          }).join('\n');

    return '''
MỤC TIÊU TÀI CHÍNH
$goalsBlock

NĂNG LỰC TIẾT KIỆM
- Trung bình tiết kiệm mỗi tháng (3 tháng gần nhất): ${Formatters.currency(avgMonthlySaving.toDouble())}
- Tỉ lệ tiết kiệm tháng này: ${(saving.currentRate * 100).toStringAsFixed(1)}%
- Tỉ lệ tiết kiệm trung bình 3 tháng: ${(saving.avgRate3m * 100).toStringAsFixed(1)}%
''';
  }
}
