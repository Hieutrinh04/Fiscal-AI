import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  String selectedFilter = "Tất cả";

  final List<String> filters = [
    "Tất cả",
    "Ăn uống",
    "Cafe",
    "Mua sắm",
    "Di chuyển",
    "Tiện ích"
  ];

  final List<Map<String, dynamic>> transactions = [
    {
      "title": "Grab Food",
      "date": "15/03/2026",
      "category": "Ăn uống",
      "amount": -85000,
      "icon": Iconsax.reserve
    },
    {
      "title": "Highland Coffee",
      "date": "15/03/2026",
      "category": "Cafe",
      "amount": -45000,
      "icon": Iconsax.coffee
    },
    {
      "title": "Shopee",
      "date": "14/03/2026",
      "category": "Mua sắm",
      "amount": -320000,
      "icon": Iconsax.shop
    },
    {
      "title": "Lương tháng 3",
      "date": "01/03/2026",
      "category": "Thu nhập",
      "amount": 15000000,
      "icon": Iconsax.money_recive
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = selectedFilter == "Tất cả"
        ? transactions
        : transactions
            .where((e) => e["category"] == selectedFilter)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),

      appBar: AppBar(
        title: const Text("Chi tiêu"),
        centerTitle: true,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SUMMARY
            Row(
              children: [
                Expanded(
                  child: summaryCard(
                      "Chi tiêu",
                      "₫2,150,000",
                      Colors.red.shade100,
                      Colors.red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: summaryCard(
                      "Thu nhập",
                      "₫15,000,000",
                      Colors.green.shade100,
                      Colors.green),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// QUICK
            const Text("Thêm nhanh"),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                QuickItem(Iconsax.reserve, "Ăn uống"),
                QuickItem(Iconsax.coffee, "Cafe"),
                QuickItem(Iconsax.shop, "Mua sắm"),
                QuickItem(Iconsax.car, "Di chuyển"),
                QuickItem(Iconsax.flash, "Tiện ích"),
              ],
            ),

            const SizedBox(height: 20),

            /// FILTER
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isActive = selectedFilter == f;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = f;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xff2F80ED)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color:
                              isActive ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            /// LIST
            Text("Giao dịch (${filteredList.length})",
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Column(
              children: filteredList.map((e) {
                final isIncome = e["amount"] > 0;

                return GestureDetector(
                  /// 🔥 LONG PRESS MENU
                  onLongPress: () {
                    _showMenu(context, e);
                  },

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(e["icon"],
                            color: isIncome
                                ? Colors.green
                                : Colors.red),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(e["title"]),
                              Text(
                                "${e["date"]} - ${e["category"]}",
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          "${isIncome ? "+" : ""}₫${e["amount"]}",
                          style: TextStyle(
                            color: isIncome
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 MENU
  void _showMenu(BuildContext context, Map data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tùy chọn",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Iconsax.edit),
                title: const Text("Chỉnh sửa"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading:
                    const Icon(Iconsax.trash, color: Colors.red),
                title: const Text("Xóa"),
                onTap: () {
                  setState(() {
                    transactions.remove(data);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget summaryCard(
      String title, String amount, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(amount,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// QUICK ITEM
class QuickItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const QuickItem(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// 🔥 CLICK → ADD TRANSACTION
      onTap: () {
        Navigator.pushNamed(context, '/add-transaction');
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 5),
          Text(text, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}