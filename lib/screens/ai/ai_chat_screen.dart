import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/snackbar.dart';

import '../../providers/ai_provider.dart';
import '../../models/ai_chat_message.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController controller = TextEditingController();

  final List<String> suggestions = [
    "Tóm tắt chi tiêu của tôi",
    "Làm sao giảm chi tiêu?",
    "Tháng này tôi tiết kiệm bao nhiêu?",
    "Có nên đầu tư không?",
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AiProvider>().loadChatHistory(user.id);
      });
    }
  }

  void sendMessage(String text) {
    if (text.isEmpty) return;
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
    // TODO: Implement delete all in AiProvider
    AppSnackBar.info(context, 'Tính năng đang được cập nhật');
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final messages = aiProvider.chatMessages;
    final isLoading = aiProvider.isLoading;
    final isSending = aiProvider.isSending;

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),

      /// ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xff2F80ED),
              child: Icon(Iconsax.cpu, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Advisor", style: TextStyle(color: Colors.black, fontSize: 16)),
                Text("Online", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            )
          ],
        ),

        /// 🔥 NÚT 3 CHẤM
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
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
              const PopupMenuItem(
                value: "copy",
                child: Text("Sao chép cuộc trò chuyện"),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: "delete",
                child: Text(
                  "Xóa lịch sử",
                  style: TextStyle(color: Colors.red),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xff2F80ED),
            child: Icon(Iconsax.cpu, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text("Xin chào! Tôi là Fiscal AI 👋",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...suggestions.map((text) => GestureDetector(
                onTap: () => sendMessage(text),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.flash, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text)),
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
                color: Colors.white,
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
              color: isUser ? const Color(0xff2F80ED) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              msg.content,
              style: TextStyle(color: isUser ? Colors.white : Colors.black),
            ),
          ),
        );
      },
    );
  }

  /// ================= INPUT =================
  Widget buildInput(bool isSending) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              onSubmitted: sendMessage,
              decoration: InputDecoration(
                hintText: "Hỏi AI...",
                prefixIcon: const Icon(Iconsax.cpu),
                filled: true,
                fillColor: const Color(0xffF3F4F6),
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
            child: CircleAvatar(
              backgroundColor: isSending ? Colors.grey : const Color(0xff2F80ED),
              child: const Icon(Iconsax.send_1, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}