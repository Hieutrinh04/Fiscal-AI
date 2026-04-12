import 'package:flutter/material.dart';

class NotificationPanel extends StatelessWidget {
  final VoidCallback onClose;

  const NotificationPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// BACKGROUND MỜ
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),

        /// PANEL
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xffF9FAFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),

            child: Column(
              children: [
                /// HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Thông báo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// LIST
                Expanded(
                  child: ListView(
                    children: const [
                      NotiItem(
                        title: "Chi tiêu ăn uống tăng 15%",
                        desc:
                            "So với tháng trước, bạn đã chi nhiều hơn cho ăn uống.",
                        time: "2 giờ trước",
                        color: Colors.orange,
                      ),
                      NotiItem(
                        title: "Đạt 60% mục tiêu quỹ khẩn cấp",
                        desc: "Tiếp tục phát huy nhé!",
                        time: "Hôm nay",
                        color: Colors.green,
                      ),
                      NotiItem(
                        title: "Nhắc nhở: Thanh toán điện nước",
                        desc: "Hạn thanh toán: 20/03/2026",
                        time: "Hôm nay",
                        color: Colors.grey,
                      ),
                      NotiItem(
                        title: "AI gợi ý mới",
                        desc:
                            "Bạn có thể tiết kiệm thêm ₫500K nếu tự pha cafe.",
                        time: "Hôm qua",
                        color: Colors.blue,
                      ),
                      NotiItem(
                        title: "Lương tháng 3 đã nhận",
                        desc: "₫15,000,000 đã được ghi nhận vào thu nhập.",
                        time: "01/03",
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ITEM
class NotiItem extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  final Color color;

  const NotiItem({
    super.key,
    required this.title,
    required this.desc,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          /// DOT
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
