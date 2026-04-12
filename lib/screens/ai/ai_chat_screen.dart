import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ COPY
import 'package:iconsax/iconsax.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  final List<String> suggestions = [
    "Tóm tắt chi tiêu của tôi",
    "Làm sao giảm chi tiêu?",
    "Tháng này tôi tiết kiệm bao nhiêu?",
    "Có nên đầu tư không?",
  ];

  /// ================= AI =================
  String getAIResponse(String text) {
    text = text.toLowerCase();

    if (text.contains("chi tiêu")) {
      return "Bạn đang chi tiêu nhiều vào ăn uống. Hãy thử giảm 15%.";
    } else if (text.contains("tiết kiệm")) {
      return "Bạn đang tiết kiệm khoảng 20% thu nhập.";
    } else if (text.contains("đầu tư")) {
      return "Bạn có thể bắt đầu với gửi tiết kiệm hoặc ETF.";
    } else {
      return "AI đang phân tích dữ liệu của bạn...";
    }
  }

  void sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      messages.add({"isUser": true, "text": text});
    });

    controller.clear();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add({
          "isUser": false,
          "text": getAIResponse(text),
        });
      });
    });
  }

  /// ================= MENU ACTION =================

  void newChat() {
    setState(() {
      messages.clear();
    });
  }

  void copyChat() {
    final text = messages.map((m) => m["text"]).join("\n");

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã sao chép cuộc trò chuyện")),
    );
  }

  void downloadChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã tải xuống file .txt (demo)")),
    );
  }

  void deleteChat() {
    setState(() {
      messages.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã xoá lịch sử")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),

      /// ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),

        title: Row(
          children: const [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xff2F80ED),
              child: Icon(Iconsax.cpu, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Advisor",
                    style: TextStyle(color: Colors.black, fontSize: 16)),
                Text("Online",
                    style: TextStyle(color: Colors.green, fontSize: 12)),
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
                case "new":
                  newChat();
                  break;
                case "copy":
                  copyChat();
                  break;
                case "download":
                  downloadChat();
                  break;
                case "delete":
                  deleteChat();
                  break;
              }
            },

            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "new",
                child: Text("Cuộc trò chuyện mới"),
              ),
              const PopupMenuItem(
                value: "copy",
                child: Text("Sao chép cuộc trò chuyện"),
              ),
              const PopupMenuItem(
                value: "download",
                child: Text("Tải xuống (.txt)"),
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
            child: messages.isEmpty ? buildWelcome() : buildChat(),
          ),
          buildInput(),
        ],
      ),
    );
  }

  /// ================= WELCOME =================
  Widget buildWelcome() {
    return Column(
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
                margin: const EdgeInsets.all(10),
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
    );
  }

  /// ================= CHAT =================
  Widget buildChat() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final isUser = msg["isUser"];

        return Align(
          alignment:
              isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xff2F80ED)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              msg["text"],
              style: TextStyle(
                  color: isUser ? Colors.white : Colors.black),
            ),
          ),
        );
      },
    );
  }

  /// ================= INPUT =================
  Widget buildInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
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
            onTap: () => sendMessage(controller.text),
            child: const CircleAvatar(
              backgroundColor: Color(0xff2F80ED),
              child: Icon(Iconsax.send_1, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}