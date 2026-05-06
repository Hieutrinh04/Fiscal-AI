import 'package:flutter/material.dart';
import '../models/ai_insight.dart';
import '../models/ai_chat_message.dart';
import '../services/ai_service.dart';

class AiProvider extends ChangeNotifier {
  final AiService _aiService = AiService();

  List<AiInsight> _insights = [];
  List<AiChatMessage> _chatMessages = [];
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isSending = false;
  bool _insightsLoaded = false;
  String? _error;

  /// Context tài chính để gửi cho Gemini
  String? _financialContext;
  String? get financialContext => _financialContext;

  /// Tên người dùng để AI chào
  String? _userName;
  String? get userName => _userName;

  void setUserName(String? name) {
    _userName = name;
  }

  List<AiInsight> get insights => _insights;
  List<AiInsight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();
  List<AiChatMessage> get chatMessages => _chatMessages;
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// 🔥 SET FINANCIAL CONTEXT
  /// Gọi từ HomeScreen sau khi load xong wallets + transactions
  void setFinancialContext(String context) {
    _financialContext = context;
  }

  /// 🔥 LOAD INSIGHTS (từ DB, không gọi Gemini)
  /// Chỉ load 1 lần mỗi session, tránh lặp request
  Future<void> loadInsights(String userId, {bool force = false}) async {
    if (_insightsLoaded && !force) return;
    _setLoading(true);
    try {
      final data = await _aiService.getSavedInsights(userId);
      if (data.isNotEmpty) {
        _insights = data.map((e) => AiInsight.fromJson(e)).toList();
      } else {
        // Nếu chưa có insight nào trong DB, mới gọi Gemini
        final insight = await _aiService.getInsights(
          userId,
          financialContext: _financialContext,
        );
        _insights = [AiInsight.fromJson(insight)];
      }
      _insightsLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// 🔥 GENERATE NEW INSIGHT (gọi Gemini, dùng khi user muốn refresh)
  Future<void> generateNewInsight(String userId) async {
    _setLoading(true);
    try {
      final data = await _aiService.getInsights(
        userId,
        financialContext: _financialContext,
      );
      _insights = [AiInsight.fromJson(data)];
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  /// 🔥 MARK AS READ
  Future<void> markInsightAsRead(String insightId) async {
    try {
      await _aiService.markInsightAsRead(insightId);

      final index = _insights.indexWhere((i) => i.id == insightId);
      if (index != -1) {
        _insights[index] =
            _insights[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// 🔥 LOAD CHAT HISTORY
  Future<void> loadChatHistory(String userId) async {
    _setLoading(true);
    _currentSessionId = userId;

    try {
      final data = await _aiService.getChatHistory(userId);

      _chatMessages =
          data.map((e) => AiChatMessage.fromJson(e)).toList();

      _error = null;
    } catch (e) {
      // Không fatal - vẫn cho phép chat ngay cả khi không load được history
      _chatMessages = [];
      _error = null;
    }

    _setLoading(false);
  }

  /// 🔥 SEND MESSAGE
  Future<void> sendMessage(String content) async {
    if (_currentSessionId == null) return;

    _isSending = true;
    notifyListeners();

    try {
      /// 1. Add user message
      final userMessage = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentSessionId!,
        sessionId: _currentSessionId!,
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      );

      _chatMessages.add(userMessage);
      notifyListeners();

      /// 2. Call Gemini via REST API
      final aiReply = await _aiService.sendChatMessage(
        _currentSessionId!,
        content,
        financialContext: _chatMessages.length <= 1 ? _financialContext : null,
        userName: _chatMessages.length <= 1 ? _userName : null,
      );

      /// 3. Add AI message
      final aiMessage = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentSessionId!,
        sessionId: _currentSessionId!,
        role: 'assistant',
        content: aiReply,
        createdAt: DateTime.now(),
      );

      _chatMessages.add(aiMessage);

      _error = null;
    } catch (e) {
      // Hiển thị lỗi trong chat thay vì ẩn đi
      final errorMessage = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentSessionId!,
        sessionId: _currentSessionId!,
        role: 'assistant',
        content: '⚠️ Lỗi: $e',
        createdAt: DateTime.now(),
      );
      _chatMessages.add(errorMessage);
      _error = e.toString();
    }

    _isSending = false;
    notifyListeners();
  }

  /// 🔥 NEW SESSION
  void startNewSession(String userId) {
    _currentSessionId = userId;
    _chatMessages = [];
    _aiService.clearChatHistory();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}