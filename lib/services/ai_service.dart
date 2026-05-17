import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/env.dart';

class AiService {
  final _client = Supabase.instance.client;

  static String get _geminiApiKey => Env.geminiApiKey;
  static const String _model = 'gemini-2.5-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static const String _systemPrompt =
      'Bạn là Fiscal AI - trợ lý tài chính cá nhân thông minh. '
      'Bạn nói tiếng Việt. Hãy trả lời ngắn gọn, hữu ích và thân thiện. '
      'Nếu người dùng hỏi về tài chính, hãy đưa ra lời khuyên thực tế dựa trên dữ liệu họ cung cấp. '
      'Nếu không có đủ dữ liệu, hãy xin thêm thông tin. '
      'Không đưa ra lời khuyên đầu tư chuyên nghiệp, chỉ gợi ý chung.';

  /// Lịch sử chat cho multi-turn (Gemini format: {role: user|model, parts: [{text}]})
  final List<Map<String, dynamic>> _chatHistory = [];

  /// Rate limiting - tối thiểu 10s giữa các API call
  DateTime? _lastApiCall;
  static const int _minIntervalSeconds = 10;

  Future<void> _waitForRateLimit() async {
    if (_lastApiCall != null) {
      final elapsed = DateTime.now().difference(_lastApiCall!);
      if (elapsed.inSeconds < _minIntervalSeconds) {
        final wait = Duration(seconds: _minIntervalSeconds) - elapsed;
        await Future.delayed(wait);
      }
    }
    _lastApiCall = DateTime.now();
  }

  /// ===============================
  /// 🔥 SEND MESSAGE (REST API)
  /// ===============================
  Future<String> sendChatMessage(
    String userId,
    String message, {
    String? financialContext,
    String? userName,
  }) async {
    try {
      await _waitForRateLimit();

      // Thêm user message vào history
      final userParts = <Map<String, dynamic>>[];
      if (_chatHistory.isEmpty) {
        final ctxParts = <String>[];
        if (userName != null && userName.isNotEmpty) {
          ctxParts.add('Tên người dùng: $userName. Hãy gọi tên họ khi chào.');
        }
        if (financialContext != null && financialContext.isNotEmpty) {
          ctxParts.add('Dữ liệu tài chính hiện tại:\n$financialContext');
        }
        if (ctxParts.isNotEmpty) {
          userParts.add({'text': '${ctxParts.join('\n\n')}\n\n'});
        }
      }
      userParts.add({'text': message});

      _chatHistory.add({'role': 'user', 'parts': userParts});

      final requestBody = {
        'contents': _chatHistory.toList(),
        'systemInstruction': {
          'parts': [{'text': _systemPrompt}],
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        },
      };

      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_geminiApiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>;
          final aiReply = parts.map((p) => p['text'] ?? '').join('');

          // Thêm AI reply vào history
          _chatHistory.add({
            'role': 'model',
            'parts': [{'text': aiReply}],
          });

          /// lưu lịch sử (không block nếu fail)
          try {
            await _saveChatHistory(userId, message, aiReply);
          } catch (e) {
            print('[AI_HISTORY] Lỗi lưu lịch sử: $e');
          }

          return aiReply;
        }
      }

      // 429: Rate limit
      if (response.statusCode == 429) {
        final retrySec = _parseRetryDelay(response.body);
        throw Exception('Gửi quá nhanh! Vui lòng đợi ${retrySec}s rồi gửi lại.');
      }

      // Lỗi khác
      throw Exception(_parseGeminiError(response));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$e');
    }
  }

  /// ===============================
  /// 🔥 CLEAR CHAT HISTORY
  /// ===============================
  void clearChatHistory() {
    _chatHistory.clear();
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
  /// 🔥 DELETE ALL CHAT HISTORY
  /// ===============================
  Future<void> deleteAllChatHistory(String userId) async {
    await _client
        .from('ai_chat_history')
        .delete()
        .eq('user_id', userId);
  }

  /// ===============================
  /// 🔥 GET INSIGHTS (Gemini REST)
  /// ===============================
  Future<Map<String, dynamic>> getInsights(String userId, {String? financialContext}) async {
    try {
      final prompt = financialContext != null
          ? 'Dựa trên dữ liệu tài chính sau, hãy đưa ra 1 insight ngắn (2-3 câu) về tình hình tài chính và 1 lời khuyên cụ thể:\n$financialContext\n\n'
              'Trả lời theo JSON format: {"type": "spending|saving|budget|general", "title": "...", "content": "..."}'
          : 'Hãy đưa ra 1 lời khuyên tài chính cá nhân ngắn gọn cho ngày hôm nay. '
              'Trả lời theo JSON format: {"type": "general", "title": "...", "content": "..."}';

      final text = await _callGemini(prompt);

      // Parse JSON từ response (dùng jsonDecode để un-escape đúng \n, \", ...)
      Map<String, dynamic> insight;
      try {
        final cleaned = _extractJsonBlock(text);
        if (cleaned != null) {
          final decoded = jsonDecode(cleaned);
          if (decoded is Map<String, dynamic>) {
            insight = decoded;
          } else {
            insight = {'type': 'general', 'title': 'Gợi ý tài chính', 'content': text.trim()};
          }
        } else {
          insight = {'type': 'general', 'title': 'Gợi ý tài chính', 'content': text.trim()};
        }
      } catch (_) {
        insight = {'type': 'general', 'title': 'Gợi ý tài chính', 'content': text.trim()};
      }

      /// lưu DB (non-blocking)
      try {
        await _saveInsight(userId, insight);
      } catch (_) {}

      return insight;
    } catch (e) {
      throw Exception('Lỗi lấy insights: $e');
    }
  }

  /// ===============================
  /// 🔥 CLASSIFY TRANSACTION (Gemini REST)
  /// ===============================
  Future<String?> classifyTransaction(String description) async {
    try {
      final prompt = 'Phân loại giao dịch sau vào 1 trong các danh mục: '
          'food, transport, shopping, entertainment, health, education, bills, salary, freelance, investment, other. '
          'Chỉ trả lời tên danh mục, không giải thích.\n\n'
          'Mô tả: $description';

      final text = await _callGemini(prompt);

      return text.trim().toLowerCase();
    } catch (e) {
      return null;
    }
  }

  /// ===============================
  /// 🔥 FORECAST (Gemini REST)
  /// ===============================
  Future<Map<String, dynamic>?> getForecast(String userId, {String? financialContext}) async {
    try {
      if (financialContext == null) return null;

      final prompt = 'Dựa trên dữ liệu tài chính sau, hãy dự báo xu hướng chi tiêu '
          'cho tháng tới và đưa ra gợi ý tiết kiệm:\n$financialContext\n\n'
          'Trả lời theo JSON: {"trend": "increasing|decreasing|stable", '
          '"predicted_expense": "số tiền ước tính", "advice": "..."}';

      final text = await _callGemini(prompt);

      final jsonMatch = RegExp(r'\{[^{}]+\}').firstMatch(text);
      if (jsonMatch != null) {
        return _parseSimpleJson(jsonMatch.group(0)!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extract JSON block từ response (xử lý markdown ```json và text xung quanh)
  String? _extractJsonBlock(String text) {
    if (text.isEmpty) return null;
    final fenced =
        RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```').firstMatch(text);
    if (fenced != null) return fenced.group(1);

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }

  /// Legacy simple JSON parser
  Map<String, dynamic> _parseSimpleJson(String json) {
    final result = <String, dynamic>{};
    final regex = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
    for (final match in regex.allMatches(json)) {
      result[match.group(1)!] = match.group(2)!;
    }
    return result;
  }

  /// ===============================
  /// 🔥 SUGGEST CATEGORY (1-shot, fail silent)
  /// ===============================
  Future<String?> suggestCategory({
    required String note,
    required List<Map<String, String>> categories,
  }) async {
    if (note.trim().isEmpty || categories.isEmpty) return null;

    try {
      final catList = categories
          .map((c) => '- ${c['id']}: ${c['name']} ${c['icon'] ?? ''}')
          .join('\n');

      final prompt = 'Bạn là bộ phân loại giao dịch tài chính. '
          'Dựa trên mô tả, chọn DUY NHẤT 1 danh mục phù hợp nhất từ list.\n\n'
          'Mô tả: "$note"\n\n'
          'Danh mục (id: tên):\n$catList\n\n'
          'Chỉ trả về đúng id (không giải thích, không markdown). '
          'Nếu không có danh mục phù hợp → trả về "NONE".';

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [{'text': prompt}],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 50,
        },
      };

      final url =
          Uri.parse('$_baseUrl/$_model:generateContent?key=$_geminiApiKey');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = candidates[0]['content']['parts'] as List<dynamic>;
      final raw = parts.map((p) => p['text'] ?? '').join('').trim();
      if (raw.isEmpty || raw.toUpperCase().contains('NONE')) return null;

      final id = raw.split(RegExp(r'\s+')).first.trim();
      final exists = categories.any((c) => c['id'] == id);
      return exists ? id : null;
    } catch (_) {
      return null; // fail silently
    }
  }

  /// ===============================
  /// 🔥 HELPER: Call Gemini REST API (single turn)
  /// ===============================
  Future<String> _callGemini(String prompt) async {
    await _waitForRateLimit();

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': prompt}],
        },
      ],
      'systemInstruction': {
        'parts': [{'text': _systemPrompt}],
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_geminiApiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List<dynamic>;
        return parts.map((p) => p['text'] ?? '').join('');
      }
    }

    if (response.statusCode == 429) {
      final retrySec = _parseRetryDelay(response.body);
      throw Exception('Gửi quá nhanh! Vui lòng đợi ${retrySec}s rồi gửi lại.');
    }

    throw Exception(_parseGeminiError(response));
  }

  /// Parse lỗi từ Gemini response
  String _parseGeminiError(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final msg = body['error']?['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'Lỗi Gemini (${response.statusCode})';
  }

  /// Parse retry delay từ Gemini 429 response
  int _parseRetryDelay(String responseBody) {
    try {
      // Gemini: "Please retry in 29.352435973s"
      final match = RegExp(r'retry in ([\d.]+)s').firstMatch(responseBody);
      if (match != null) return double.parse(match.group(1)!).ceil();
      // Fallback: tìm retryDelay
      final match2 = RegExp(r'retryDelay[":\s]+(\d+)s').firstMatch(responseBody);
      if (match2 != null) return int.parse(match2.group(1)!);
    } catch (_) {}
    return 30; // mặc định 30s
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
  /// 🔥 MARK AS READ
  /// ===============================
  Future<void> markInsightAsRead(String insightId) async {
    await _client
        .from('ai_insights')
        .update({'is_read': true})
        .eq('id', insightId);
  }
}