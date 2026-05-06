import 'package:intl/intl.dart';
import 'constants.dart';

class Formatters {
  // Currency
  static String currency(double amount, {String symbol = '₫'}) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}$symbol';
  }

  static String currencyCompact(double amount) {
    if (amount >= 1e9) return '${(amount / 1e9).toStringAsFixed(1)}tỷ';
    if (amount >= 1e6) return '${(amount / 1e6).toStringAsFixed(1)}tr';
    if (amount >= 1e3) return '${(amount / 1e3).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }

  // Date
  static String date(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  static String dateShort(DateTime dt) {
    return DateFormat('dd/MM').format(dt);
  }

  static String monthYear(DateTime dt) {
    return DateFormat('MM/yyyy').format(dt);
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} năm trước';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} tháng trước';
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  static String dayOfWeek(DateTime dt) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[dt.weekday % 7];
  }

  // Percentage
  static String percent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Number
  static String number(double value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(value);
  }

  // Transaction type label
  static String transactionType(String type) {
    switch (type) {
      case 'income': return 'Thu nhập';
      case 'expense': return 'Chi tiêu';
      case 'transfer': return 'Chuyển khoản';
      default: return type;
    }
  }

  // Goal status label
  static String goalStatus(String status) {
    switch (status) {
      case 'active': return 'Đang thực hiện';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  // Category emoji from icon string
  static String categoryEmoji(String? icon) {
    if (icon == null || icon.isEmpty) return '📦';
    if (icon.length <= 2 && icon.runes.first > 0x1F000) return icon;
    return AppConstants.categoryEmojis[icon.toLowerCase()] ?? icon;
  }

  // Wallet emoji from wallet name
  static String walletEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ngân hàng') || lower.contains('bank')) return '🏦';
    if (lower.contains('momo') || lower.contains('ví')) return '📱';
    if (lower.contains('tiết kiệm')) return '🐷';
    return '💳';
  }
}
