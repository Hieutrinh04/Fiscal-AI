import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),

      body: Column(
        children: [
          /// ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ví tiền",
                    style: TextStyle(color: Colors.white, fontSize: 16)),

                const SizedBox(height: 8),

                const Text("đ47.000.000",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _button("Chuyển tiền", Iconsax.arrow_up),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _button("Nhận tiền", Iconsax.arrow_down),
                    ),
                  ],
                )
              ],
            ),
          ),

          /// ================= BODY =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// AI CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffEAF3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.cpu, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "AI gợi ý: Bạn nên chuyển thêm 2M vào tiết kiệm",
                          style: TextStyle(color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// ACCOUNT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Tài khoản của tôi",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("+ Thêm",
                        style: TextStyle(color: Colors.blue)),
                  ],
                ),

                const SizedBox(height: 12),

                _accountItem("Ví tiền mặt", "Tiền mặt", "đ3.420.000",
                    Iconsax.wallet),
                _accountItem("Vietcombank", "Ngân hàng", "đ12.080.000",
                    Iconsax.bank),
                _accountItem("Momo", "Ví điện tử", "đ1.500.000",
                    Iconsax.card),
                _accountItem("Tiết kiệm", "Tiết kiệm", "đ30.000.000",
                    Iconsax.money),

                const SizedBox(height: 20),

                /// TRANSACTION
                const Text("Hoạt động gần đây",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                const SizedBox(height: 10),

                _transaction("Chuyển tiền → Tiết kiệm", "Hôm nay",
                    "-đ5.000.000", Iconsax.send_1),
                _transaction("Nhận lương", "01/03", "+đ15.000.000",
                    Iconsax.money_recive,
                    isIncome: true),
                _transaction("Rút tiền ATM", "28/02", "-đ2.000.000",
                    Iconsax.card_remove),
                _transaction("Chuyển khoản MoMo", "27/02", "-đ500.000",
                    Iconsax.mobile),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// BUTTON
  Widget _button(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// ACCOUNT
  Widget _accountItem(
      String title, String sub, String amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(sub,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          Text(amount,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// TRANSACTION
  Widget _transaction(String title, String date, String amount,
      IconData icon,
      {bool isIncome = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isIncome ? Colors.green : Colors.red),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(date,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}