import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/ai_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/markdown_text.dart';

class AiChatHistoryScreen extends StatefulWidget {
  const AiChatHistoryScreen({super.key});

  @override
  State<AiChatHistoryScreen> createState() => _AiChatHistoryScreenState();
}

class _AiChatHistoryScreenState extends State<AiChatHistoryScreen> {
  final _service = AiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _rows = [];

  static const _primaryColor = Color(0xff2F80ED);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await _service.getChatHistory(user.id, limit: 200);
        setState(() => _rows = data);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  /// Nhóm rows theo ngày
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final row in _rows.reversed) {
      final dt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
      final key = _dateLabel(dt);
      map.putIfAbsent(key, () => []).add(row);
    }
    return map;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) return '$diff ngày trước';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _viewConversation(List<Map<String, dynamic>> rows) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConversationSheet(rows: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(context.l10n.chatHistoryTitle,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dateKeys.length,
                    itemBuilder: (_, i) {
                      final key = dateKeys[i];
                      final items = grouped[key]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(key,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff9CA3AF),
                                    letterSpacing: 1.1)),
                          ),
                          ...items.map((row) => _buildItem(row, items)),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildItem(Map<String, dynamic> row, List<Map<String, dynamic>> dayRows) {
    final userMsg = row['user_message'] as String? ?? '';
    final aiReply = row['ai_reply'] as String? ?? '';
    final dt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _viewConversation(dayRows),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.message_text_1,
                      color: _primaryColor, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userMsg.length > 60
                        ? '${userMsg.substring(0, 60)}...'
                        : userMsg,
                    style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Text(timeStr,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xff9CA3AF))),
              ],
            ),
            if (aiReply.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  aiReply.length > 100
                      ? '${aiReply.substring(0, 100)}...'
                      : aiReply,
                  style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xff6B7280),
                      height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.message, size: 56, color: Color(0xffD1D5DB)),
          const SizedBox(height: 16),
          Text(context.l10n.noChatHistory,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff6B7280))),
          const SizedBox(height: 6),
          Text(context.l10n.chatInputHint,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xff9CA3AF))),
        ],
      ),
    );
  }
}

/// ===== SHEET xem cuộc hội thoại đầy đủ =====
class _ConversationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _ConversationSheet({required this.rows});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(context.l10n.chatHistoryTitle,
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: rows.length * 2,
                itemBuilder: (_, i) {
                  final rowIndex = i ~/ 2;
                  final isUser = i % 2 == 0;
                  final row = rows[rowIndex];
                  final content = isUser
                      ? (row['user_message'] as String? ?? '')
                      : (row['ai_reply'] as String? ?? '');
                  if (content.isEmpty) return const SizedBox.shrink();
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xff2F80ED)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: MarkdownText(
                        content,
                        style: GoogleFonts.inter(
                          color: isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
