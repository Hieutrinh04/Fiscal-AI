import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  DateTime selectedDate = DateTime.now();

  final TextEditingController amountController =
      TextEditingController();
  final TextEditingController descController =
      TextEditingController();

  String selectedCategory = "Ăn uống";

  /// ================= CATEGORY =================

  final List<Map<String, dynamic>> expenseCategories = [
    {"name": "Ăn uống", "icon": Iconsax.reserve, "color": Colors.red},
    {"name": "Cafe", "icon": Iconsax.coffee, "color": Colors.orange},
    {"name": "Mua sắm", "icon": Iconsax.shop, "color": Colors.blue},
    {"name": "Di chuyển", "icon": Iconsax.car, "color": Colors.green},
    {"name": "Tiện ích", "icon": Iconsax.flash, "color": Colors.grey},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {"name": "Tiền lương", "icon": Iconsax.money_recive, "color": Colors.green},
    {"name": "Thưởng", "icon": Iconsax.gift, "color": Colors.amber},
    {"name": "Đầu tư", "icon": Iconsax.chart_2, "color": Colors.blue},
    {"name": "Freelance", "icon": Iconsax.briefcase, "color": Colors.teal},
    {"name": "Khác", "icon": Iconsax.more, "color": Colors.grey},
  ];

  /// ================= AI =================

  void autoCategory(String text) {
    text = text.toLowerCase();

    if (isExpense) {
      if (text.contains("ăn") || text.contains("phở") || text.contains("cơm")) {
        selectedCategory = "Ăn uống";
      } else if (text.contains("cafe") || text.contains("trà")) {
        selectedCategory = "Cafe";
      } else if (text.contains("grab") || text.contains("taxi")) {
        selectedCategory = "Di chuyển";
      } else if (text.contains("mua") || text.contains("shop")) {
        selectedCategory = "Mua sắm";
      }
    } else {
      if (text.contains("lương")) {
        selectedCategory = "Tiền lương";
      } else if (text.contains("thưởng")) {
        selectedCategory = "Thưởng";
      } else if (text.contains("freelance")) {
        selectedCategory = "Freelance";
      } else if (text.contains("đầu tư")) {
        selectedCategory = "Đầu tư";
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    descController.addListener(() {
      autoCategory(descController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCategories =
        isExpense ? expenseCategories : incomeCategories;

    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Thêm giao dịch",
            style: TextStyle(color: Colors.black)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= SWITCH =================
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpense = true;
                          selectedCategory = "Ăn uống";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isExpense ? Colors.red : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Chi tiêu",
                            style: TextStyle(
                              color:
                                  isExpense ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpense = false;
                          selectedCategory = "Tiền lương";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              !isExpense ? Colors.green : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Thu nhập",
                            style: TextStyle(
                              color:
                                  !isExpense ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ================= AMOUNT =================
            const Text("Số tiền (₫)"),
            const SizedBox(height: 8),
            buildInput(amountController, "0", Iconsax.money),

            const SizedBox(height: 16),

            /// ================= DESCRIPTION =================
            const Text("Mô tả (AI tự phân loại)"),
            const SizedBox(height: 8),
            buildInput(descController, "VD: ăn phở", Iconsax.note),

            const SizedBox(height: 6),

            Text(
              "🤖 AI gợi ý: $selectedCategory",
              style: const TextStyle(color: Colors.blue),
            ),

            const SizedBox(height: 16),

            /// ================= DATE =================
            const Text("Ngày"),
            const SizedBox(height: 8),
            buildDate(),

            const SizedBox(height: 16),

            /// ================= CATEGORY =================
            const Text("Danh mục"),
            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: currentCategories.map((cat) {
                final isSelected = selectedCategory == cat["name"];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat["name"];
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cat["color"].withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Icon(cat["icon"], color: cat["color"]),
                      ),
                      const SizedBox(height: 5),
                      Text(cat["name"],
                          style: const TextStyle(fontSize: 12))
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            /// ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isExpense ? Colors.red : Colors.green,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  isExpense ? "Thêm chi tiêu" : "Thêm thu nhập",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= COMPONENT =================

  Widget buildInput(
      TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildDate() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          setState(() => selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
            const Icon(Iconsax.calendar),
          ],
        ),
      ),
    );
  }
}