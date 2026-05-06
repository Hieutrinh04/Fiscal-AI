import 'package:flutter/material.dart';

class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://opwcjrmxzovfgqrjfrhg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt';

  // App
  static const String appName = 'FinBuddy AI';
  static const String currency = 'VND';
  static const String locale = 'vi_VN';

  // Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color incomeColor = Color(0xFF22C55E);
  static const Color expenseColor = Color(0xFFEF4444);
  static const Color transferColor = Color(0xFF3B82F6);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    '#F59E0B': Color(0xFFF59E0B),
    '#10B981': Color(0xFF10B981),
    '#8B5CF6': Color(0xFF8B5CF6),
    '#EC4899': Color(0xFFEC4899),
    '#06B6D4': Color(0xFF06B6D4),
    '#92400E': Color(0xFF92400E),
    '#6B7280': Color(0xFF6B7280),
    '#22C55E': Color(0xFF22C55E),
    '#A855F7': Color(0xFFA855F7),
    '#0EA5E9': Color(0xFF0EA5E9),
  };

  // Transaction Types
  static const String income = 'income';
  static const String expense = 'expense';
  static const String transfer = 'transfer';

  // Goal Status
  static const String goalActive = 'active';
  static const String goalCompleted = 'completed';
  static const String goalCancelled = 'cancelled';

  // Budget Period
  static const String monthly = 'monthly';
  static const String weekly = 'weekly';
  static const String yearly = 'yearly';

  // Notification Types
  static const String notifBudgetWarning = 'budget_warning';
  static const String notifGoalReminder = 'goal_reminder';
  static const String notifAiInsight = 'ai_insight';
  static const String notifSystem = 'system';

  // Pagination
  static const int pageSize = 20;

  // Budget Warning Threshold
  static const double budgetWarningPercent = 80.0;

  // Wallet Types
  static const List<String> walletTypes = ['Tiền mặt', 'Ngân hàng', 'Ví điện tử', 'Tiết kiệm'];

  // Wallet Emojis
  static const List<String> walletEmojis = ['💳', '🏦', '📱', '🐷', '💰', '💼', '🏠', '🎯', '🔒', '✈️', '🛒', '🎁'];

  // Category Emojis (key → emoji)
  static const Map<String, String> categoryEmojis = {
    'food': '🍔', 'transport': '🚗', 'shopping': '🛍️', 'entertainment': '🎬',
    'health': '💊', 'education': '📚', 'bills': '📄', 'travel': '✈️',
    'gift': '🎁', 'salary': '💰', 'freelance': '💻', 'investment': '📈',
    'refund': '🔄', 'bonus': '🎉', 'other': '📦',
  };
}
