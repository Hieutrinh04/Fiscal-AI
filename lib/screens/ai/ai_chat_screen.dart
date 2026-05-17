import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/snackbar.dart';
import '../../utils/ai_context.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/markdown_text.dart';

import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ai_chat_message.dart';
import 'ai_chat_history_screen.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController controller = TextEditingController();

  List<String> _suggestions(BuildContext context) => context.l10n.locale.languageCode == 'vi'
      ? ['Tóm tắt chi tiêu của tôi', 'Làm sao giảm chi tiêu?', 'Tháng này tôi tiết kiệm bao nhiêu?', 'Có nên đầu tư không?']
      : ['Summarize my expenses', 'How to cut spending?', 'How much did I save this month?', 'Should I invest?'];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Refresh snapshot tài chính (ví, thu/chi, mục tiêu) cho AI
        _refreshFinancialContext();
        context.read<AiProvider>().loadChatHistory(user.id);
      });
    }
  }

  /// Rebuild context tài chính từ dữ liệu mới nhất và inject vào AiProvider.
  /// Gọi trước mỗi lần gửi để AI luôn có thông tin cập nhật.
  void _refreshFinancialContext() {
    final aiProvider = context.read<AiProvider>();
    final authProvider = context.read<AuthProvider>();
    aiProvider.setFinancialContext(AiContextBuilder.build(context));
    aiProvider.setUserName(authProvider.profile?.fullName);
  }

  void sendMessage(String text) {
    if (text.isEmpty) return;
    // Refresh context ngay trước khi gửi — dữ liệu có thể đã đổi từ khi mở màn
    _refreshFinancialContext();
    context.read<AiProvider>().sendMessage(text);
    controller.clear();
  }

  /// ================= MENU ACTION =================

  void copyChat() {
    final messages = context.read<AiProvider>().chatMessages;
    final text = messages.map((m) => "${m.role}: ${m.content}").join("\n");

    Clipboard.setData(ClipboardData(text: text));

    AppSnackBar.success(context, 'Đã sao chép cuộc trò chuyện');
  }

  void deleteChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá lịch sử chat'),
        content: const Text('Bạn có chắc muốn xoá toàn bộ lịch sử trò chuyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AiProvider>().deleteAllChatHistory();
              if (mounted) AppSnackBar.success(context, 'Đã xoá lịch sử chat');
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiChatHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final messages = aiProvider.chatMessages;
    final isLoading = aiProvider.isLoading;
    final isSending = aiProvider.isSending;

    return Scaffold(
      /// ================= APPBAR =================
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xff2F80ED),
              child: Icon(Iconsax.cpu, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.aiAssistant,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text(context.l10n.aiOnline,
                    style: GoogleFonts.inter(
                        color: Colors.green.shade400, fontSize: 11)),
              ],
            )
          ],
        ),

        /// 🔥 ACTIONS
        actions: [
          IconButton(
            icon: const Icon(Iconsax.clock, size: 20),
            tooltip: 'Lịch sử chat',
            onPressed: openHistory,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case "copy":
                  copyChat();
                  break;
                case "delete":
                  deleteChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "copy",
                child: Text(context.l10n.copyChat),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: "delete",
                child: Text(
                  context.l10n.deleteHistory,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),

      /// ================= BODY =================
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? buildWelcome()
                    : buildChat(messages, isSending),
          ),
          buildInput(isSending),
        ],
      ),
    );
  }

  /// ================= WELCOME =================
  Widget buildWelcome() {
    final userName = context.watch<AiProvider>().userName;
    final greeting = userName != null && userName.isNotEmpty
        ? 'Xin chào, $userName! 👋'
        : 'Xin chào! 👋';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2F80ED).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Iconsax.cpu, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            greeting,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xff1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tôi là Fiscal AI — trợ lý tài chính của bạn.\nHỏi tôi bất cứ điều gì về tiền bạc nhé! 💰',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: const Color(0xff6B7280),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'GỢI Ý CHO BẠN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff9CA3AF),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._suggestions(context).map((text) => GestureDetector(
                onTap: () => sendMessage(text),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xff2F80ED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.flash_1,
                            color: Color(0xff2F80ED), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Iconsax.arrow_right_3,
                          color: Color(0xff9CA3AF), size: 16),
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }

  /// ================= CHAT =================
  Widget buildChat(List<AiChatMessage> messages, bool isSending) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msg = messages[i];
        final isUser = msg.role == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xff2F80ED) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!isUser)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: MarkdownText(
              msg.content,
              style: GoogleFonts.inter(
                color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: 14.5,
                height: 1.55,
                letterSpacing: 0.1,
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================= INPUT =================
  Widget buildInput(bool isSending) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                onSubmitted: sendMessage,
                style: GoogleFonts.inter(fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: context.l10n.chatInputHint,
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xff9CA3AF),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Iconsax.message_text_1,
                      color: Color(0xff2F80ED), size: 20),
                  filled: true,
                  fillColor: const Color(0xffF3F4F6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isSending ? null : () => sendMessage(controller.text),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSending
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
                        ),
                  color: isSending ? Colors.grey.shade300 : null,
                  boxShadow: isSending
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xff2F80ED).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: const Icon(Iconsax.send_1,
                    color: Colors.white, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}