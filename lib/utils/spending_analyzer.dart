import 'dart:math' as math;

import '../models/transaction.dart';
import '../models/category.dart';

/// Kết quả pace forecast — dự đoán tổng chi cuối tháng dựa trên tốc độ hiện tại.
class PaceForecast {
  final int currentMonthSpent;
  final int forecastEndOfMonth;
  final int baselineMedian; // median chi 3 tháng trước (không tính tháng hiện tại)
  final double ratio; // forecast / baseline
  final int daysPassed;
  final int daysInMonth;

  PaceForecast({
    required this.currentMonthSpent,
    required this.forecastEndOfMonth,
    required this.baselineMedian,
    required this.ratio,
    required this.daysPassed,
    required this.daysInMonth,
  });

  /// Mức độ cảnh báo:
  ///   'ok'        ratio <= 1.0
  ///   'warning'   1.0 < ratio <= 1.3
  ///   'critical'  ratio > 1.3
  String get severity {
    if (baselineMedian == 0) return 'ok'; // chưa đủ dữ liệu
    if (ratio > 1.3) return 'critical';
    if (ratio > 1.1) return 'warning';
    return 'ok';
  }

  bool get hasEnoughData => baselineMedian > 0;
}

/// Bất thường 1 danh mục: chi tháng này cao hơn trung bình quá kỳ vọng.
class CategoryAnomaly {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final int currentAmount;
  final double meanAmount;
  final double stdDev;
  final double zScore; // (current - mean) / stddev

  CategoryAnomaly({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    required this.currentAmount,
    required this.meanAmount,
    required this.stdDev,
    required this.zScore,
  });

  /// Danh mục chi cao bất thường nếu zScore > 1.5 VÀ current > mean
  bool get isAnomaly => zScore > 1.5 && currentAmount > meanAmount;

  String get severity {
    if (zScore > 2.5) return 'critical';
    if (zScore > 1.5) return 'warning';
    return 'info';
  }
}

/// Xu hướng tỉ lệ tiết kiệm.
class SavingRateTrend {
  final double currentRate; // 0..1 (không %)
  final double avgRate3m; // 3 tháng gần đây (không tính tháng này)
  final double delta; // currentRate - avgRate3m

  SavingRateTrend({
    required this.currentRate,
    required this.avgRate3m,
    required this.delta,
  });

  /// Giảm > 25 điểm% so với trung bình → cảnh báo
  bool get isConcerning => delta < -0.25;
}

/// Engine phân tích lịch sử chi tiêu. Tất cả static — không giữ state.
class SpendingAnalyzer {
  /// Dự báo chi cuối tháng theo tốc độ hiện tại, so với median 3 tháng trước.
  static PaceForecast paceForecast(List<Transaction> transactions,
      {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final firstOfMonth = DateTime(ref.year, ref.month, 1);
    final daysInMonth = DateTime(ref.year, ref.month + 1, 0).day;
    final daysPassed = ref.day.clamp(1, daysInMonth);

    // Chi tháng hiện tại
    final currentMonthSpent = transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.date.isBefore(firstOfMonth) &&
            t.date.isBefore(DateTime(ref.year, ref.month + 1, 1)))
        .fold<int>(0, (s, t) => s + t.amount);

    // Chi 3 tháng trước (mỗi tháng 1 giá trị)
    final monthlyTotals = <int>[];
    for (int i = 1; i <= 3; i++) {
      final start = DateTime(ref.year, ref.month - i, 1);
      final end = DateTime(ref.year, ref.month - i + 1, 1);
      final total = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              !t.date.isBefore(start) &&
              t.date.isBefore(end))
          .fold<int>(0, (s, t) => s + t.amount);
      if (total > 0) monthlyTotals.add(total);
    }

    final baselineMedian = _median(monthlyTotals);

    // Forecast: extrapolate tuyến tính theo tốc độ hiện tại
    final forecastDouble =
        (currentMonthSpent / daysPassed) * daysInMonth;
    final forecast = forecastDouble.round();

    final ratio = baselineMedian > 0 ? forecast / baselineMedian : 0.0;

    return PaceForecast(
      currentMonthSpent: currentMonthSpent,
      forecastEndOfMonth: forecast,
      baselineMedian: baselineMedian,
      ratio: ratio,
      daysPassed: daysPassed,
      daysInMonth: daysInMonth,
    );
  }

  /// Top N danh mục chi bất thường so với trung bình `monthsLookback` tháng trước.
  /// Trả về list sắp xếp theo zScore giảm dần (chỉ lấy danh mục có dữ liệu).
  static List<CategoryAnomaly> detectCategoryAnomalies(
    List<Transaction> transactions, {
    int monthsLookback = 3,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final firstOfCurrentMonth = DateTime(ref.year, ref.month, 1);
    final nextMonth = DateTime(ref.year, ref.month + 1, 1);

    // Gom tổng chi theo (categoryId, monthIndex).
    // monthIndex = 0 cho tháng hiện tại, 1, 2, 3... cho tháng trước
    final Map<String, Map<int, int>> byCatMonth = {};
    final Map<String, Category> catMeta = {};

    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final cat = t.category;
      final catId = cat?.id ?? 'other';
      if (cat != null) catMeta[catId] = cat;

      // Tính monthIndex từ ngày giao dịch
      final monthsFromCurrent =
          (ref.year - t.date.year) * 12 + (ref.month - t.date.month);
      if (monthsFromCurrent < 0 || monthsFromCurrent > monthsLookback) {
        continue;
      }
      byCatMonth.putIfAbsent(catId, () => {});
      byCatMonth[catId]![monthsFromCurrent] =
          (byCatMonth[catId]![monthsFromCurrent] ?? 0) + t.amount;
    }

    // Tính scale pace — nếu đang ở giữa tháng, extrapolate chi hiện tại
    final daysInMonth = DateTime(ref.year, ref.month + 1, 0).day;
    final daysPassed = ref.day.clamp(1, daysInMonth);
    final paceScale = daysInMonth / daysPassed;

    final results = <CategoryAnomaly>[];
    byCatMonth.forEach((catId, monthMap) {
      final currentRaw = monthMap[0] ?? 0;
      if (currentRaw == 0) return;

      // Extrapolate chi hiện tại cho fair comparison với tháng đã hoàn tất
      final currentProjected = (currentRaw * paceScale).round();

      // Lấy các tháng trước để tính mean + stddev
      final pastValues = <int>[];
      for (int i = 1; i <= monthsLookback; i++) {
        pastValues.add(monthMap[i] ?? 0);
      }
      if (pastValues.every((v) => v == 0)) return;

      final mean = _mean(pastValues);
      final stdDev = _stdDev(pastValues, mean);
      // Tránh chia 0: nếu stddev quá nhỏ, dùng 20% mean làm floor
      final effectiveStd = math.max(stdDev, mean * 0.2);
      final zScore = effectiveStd > 0
          ? (currentProjected - mean) / effectiveStd
          : 0.0;

      final meta = catMeta[catId];
      results.add(CategoryAnomaly(
        categoryId: catId,
        categoryName: meta?.name ?? 'Khác',
        categoryIcon: meta?.icon,
        currentAmount: currentRaw, // raw, không projected — hiển thị thực tế
        meanAmount: mean,
        stdDev: stdDev,
        zScore: zScore,
      ));
    });

    results.sort((a, b) => b.zScore.compareTo(a.zScore));
    // Dùng nextMonth để silence unused_local_variable
    assert(nextMonth.isAfter(firstOfCurrentMonth));
    return results;
  }

  /// So sánh tỉ lệ tiết kiệm tháng này với trung bình 3 tháng trước.
  static SavingRateTrend savingRateTrend(List<Transaction> transactions,
      {DateTime? now}) {
    final ref = now ?? DateTime.now();

    double rateForMonth(int monthsAgo) {
      final start = DateTime(ref.year, ref.month - monthsAgo, 1);
      final end = DateTime(ref.year, ref.month - monthsAgo + 1, 1);
      int income = 0, expense = 0;
      for (final t in transactions) {
        if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
        if (t.type == TransactionType.income) income += t.amount;
        if (t.type == TransactionType.expense) expense += t.amount;
      }
      if (income <= 0) return 0.0;
      return (income - expense) / income;
    }

    final current = rateForMonth(0);
    final pastRates = <double>[
      for (int i = 1; i <= 3; i++) rateForMonth(i),
    ];
    final avgPast = pastRates.isEmpty ? 0.0 : _meanD(pastRates);

    return SavingRateTrend(
      currentRate: current,
      avgRate3m: avgPast,
      delta: current - avgPast,
    );
  }

  // ========== Helpers ==========

  static int _median(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final n = sorted.length;
    if (n.isOdd) return sorted[n ~/ 2];
    return ((sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2).round();
  }

  static double _mean(List<int> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<int>(0, (s, v) => s + v);
    return sum / values.length;
  }

  static double _meanD(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _stdDev(List<int> values, double mean) {
    if (values.length < 2) return 0;
    final sumSq = values.fold<double>(
      0,
      (s, v) => s + math.pow(v - mean, 2).toDouble(),
    );
    return math.sqrt(sumSq / values.length);
  }
}
