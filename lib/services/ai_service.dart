import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  final _client = Supabase.instance.client;

  /// ⚠️ TODO: thay bằng API thật
  static const String _aiBaseUrl = 'sb_publishable_prW4ZbdneWPtdpcwDhvcRQ_gBxbmkGt';

  /// ===============================
  /// 🔥 SEND MESSAGE
  /// ===============================
  Future<String> sendMessage(String userId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_aiBaseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final aiReply = data['reply'] as String;

        /// lưu lịch sử
        await _saveChatHistory(userId, message, aiReply);

        return aiReply;
      } else {
        throw Exception('AI server lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối AI: $e');
    }
  }

  /// ===============================
  /// 🔥 SAVE CHAT HISTORY
  /// ===============================
  Future<void> _saveChatHistory(
      String userId,
      String userMessage,
      String aiReply,
      ) async {
    await _client.from('ai_chat_history').insert({
      'user_id': userId,
      'user_message': userMessage,
      'ai_reply': aiReply,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// ===============================
  /// 🔥 GET CHAT HISTORY
  /// ===============================
  Future<List<Map<String, dynamic>>> getChatHistory(
      String userId, {
        int limit = 50,
      }) async {
    final data = await _client
        .from('ai_chat_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(data);
  }

  /// ===============================
  /// 🔥 GET INSIGHTS
  /// ===============================
  Future<Map<String, dynamic>> getInsights(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_aiBaseUrl/insights/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// lưu DB
        await _saveInsight(userId, data);

        return data;
      } else {
        throw Exception('Lỗi lấy insights');
      }
    } catch (e) {
      throw Exception('Không thể kết nối AI: $e');
    }
  }

  /// ===============================
  /// 🔥 SAVE INSIGHT
  /// ===============================
  Future<void> _saveInsight(
      String userId,
      Map<String, dynamic> insight,
      ) async {
    await _client.from('ai_insights').insert({
      'user_id': userId,
      'type': insight['type'] ?? 'general',
      'title': insight['title'] ?? '',
      'content': insight['content'] ?? '',
      'data': insight['data'],
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// ===============================
  /// 🔥 GET SAVED INSIGHTS
  /// ===============================
  Future<List<Map<String, dynamic>>> getSavedInsights(
      String userId) async {
    final data = await _client
        .from('ai_insights')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(data);
  }

  /// ===============================
  /// 🔥 MARK AS READ (FIX LỖI CHO BẠN)
  /// ===============================
  Future<void> markInsightAsRead(String insightId) async {
    await _client
        .from('ai_insights')
        .update({'is_read': true})
        .eq('id', insightId);
  }

  /// ===============================
  /// 🔥 CLASSIFY TRANSACTION
  /// ===============================
  Future<String?> classifyTransaction(String description) async {
    try {
      final response = await http.post(
        Uri.parse('$_aiBaseUrl/classify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['category_id'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// ===============================
  /// 🔥 FORECAST
  /// ===============================
  Future<Map<String, dynamic>?> getForecast(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_aiBaseUrl/forecast/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}