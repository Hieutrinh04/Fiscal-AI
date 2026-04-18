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
  String? _error;

  List<AiInsight> get insights => _insights;
  List<AiInsight> get unreadInsights =>
      _insights.where((i) => !i.isRead).toList();
  List<AiChatMessage> get chatMessages => _chatMessages;
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  /// 🔥 LOAD INSIGHTS
  Future<void> loadInsights(String userId) async {
    _setLoading(true);
    try {
      final data = await _aiService.getInsights(userId);

      /// Map → Model
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
      _error = e.toString();
    }

    _setLoading(false);
  }

  /// 🔥 SEND MESSAGE (FIX ID)
  Future<void> sendMessage(String content) async {
    if (_currentSessionId == null) return;

    _isSending = true;
    notifyListeners();

    try {
      /// 1. Add user message
      final userMessage = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ✅ FIX
        userId: _currentSessionId!,
        sessionId: _currentSessionId!,
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      );

      _chatMessages.add(userMessage);
      notifyListeners();

      /// 2. Call service
      final aiReply = await _aiService.sendMessage(
        _currentSessionId!,
        content,
      );

      /// 3. Add AI message
      final aiMessage = AiChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ✅ FIX
        userId: _currentSessionId!,
        sessionId: _currentSessionId!,
        role: 'assistant',
        content: aiReply,
        createdAt: DateTime.now(),
      );

      _chatMessages.add(aiMessage);

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isSending = false;
    notifyListeners();
  }

  /// 🔥 NEW SESSION
  void startNewSession(String userId) {
    _currentSessionId = userId;
    _chatMessages = [];
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