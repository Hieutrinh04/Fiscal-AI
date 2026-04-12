import 'package:flutter/material.dart';

/// 🔥 COLOR SYSTEM
const primaryColor = Color(0xff2F80ED);
const secondaryColor = Color(0xff56CCF2);

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Map<String, dynamic>> goals = [
    {'name': 'Mua nhà', 'current': 45500000, 'target': 182000000, 'icon': '🏠', 'deadline': 'Tháng 11 2026', 'monthly': 5000000},
    {'name': 'Du lịch Nhật Bản', 'current': 8000000, 'target': 20000000, 'icon': '✈️', 'deadline': 'Tháng 6 2026', 'monthly': 2000000},
    {'name': 'Quỹ khẩn cấp', 'current': 30000000, 'target': 50000000, 'icon': '🛡️', 'deadline': 'Tháng 12 2026', 'monthly': 3000000},
    {'name': 'Học MBA', 'current': 12000000, 'target': 100000000, 'icon': '🎓', 'deadline': 'Tháng 1 2028', 'monthly': 4000000},
  ];

  final List<String> iconOptions = ['🏠', '✈️', '🛡️', '🎓', '🚗', '💍', '📱', '💼', '🏖️', '🎯'];

  double get totalSaved => goals.fold(0, (s, g) => s + (g['current'] as num));
  double get totalTarget => goals.fold(0, (s, g) => s + (g['target'] as num));

  String formatMoney(num amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toString();
  }

  String formatFullMoney(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  void _showDepositDialog(int index) {
    final controller = TextEditingController();
    final goal = goals[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nạp tiền vào "${goal['name']}"',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hiện tại: ₫${formatFullMoney(goal['current'])} / ₫${formatFullMoney(goal['target'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Số tiền nạp (₫)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount <= 0) return;
                  setState(() {
                    final current = (goal['current'] as num).toDouble();
                    final target = (goal['target'] as num).toDouble();
                    goals[index]['current'] = (current + amount).clamp(0, target);
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('+₫${formatFullMoney(amount)} vào ${goal['name']}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xác nhận nạp tiền',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();
    String selectedIcon = '🎯';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thêm mục tiêu mới',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: iconOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final ic = iconOptions[i];
                    final isSelected = ic == selectedIcon;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedIcon = ic),
                      child: Container(
                        width: 44, height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
                        ),
                        child: Text(ic, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              _buildInput(nameCtrl, 'Tên mục tiêu (VD: Mua xe)'),
              const SizedBox(height: 10),
              _buildInput(targetCtrl, 'Số tiền mục tiêu (₫)', isNumber: true),
              const SizedBox(height: 10),
              _buildInput(monthlyCtrl, 'Tiết kiệm mỗi tháng (₫)', isNumber: true),
              const SizedBox(height: 10),
              _buildInput(deadlineCtrl, 'Hạn chót (VD: Tháng 12 2027)'),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty || targetCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên và số tiền mục tiêu')),
                      );
                      return;
                    }
                    setState(() {
                      goals.add({
                        'name': nameCtrl.text,
                        'current': 0,
                        'target': double.tryParse(targetCtrl.text) ?? 0,
                        'icon': selectedIcon,
                        'deadline': deadlineCtrl.text.isEmpty ? 'Chưa xác định' : deadlineCtrl.text,
                        'monthly': double.tryParse(monthlyCtrl.text) ?? 0,
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tạo mục tiêu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = totalTarget > 0 ? (totalSaved / totalTarget) : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Mục tiêu tài chính',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.gps_fixed, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text('Tiến độ tự do tài chính',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor)),
                        ]),
                        const SizedBox(height: 8),

                        RichText(text: TextSpan(children: [
                          TextSpan(
                            text: '₫${formatMoney(totalSaved)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          TextSpan(
                            text: ' / ₫${formatMoney(totalTarget)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                        ])),

                        const SizedBox(height: 8),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(primaryColor),
                          ),
                        ),

                        const SizedBox(height: 6),

                        RichText(text: TextSpan(
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          children: [
                            const TextSpan(text: 'Bạn đã đạt '),
                            TextSpan(
                              text: '${(percent * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
                            ),
                            const TextSpan(text: ' mục tiêu'),
                          ],
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.trending_up, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('AI gợi ý tiết kiệm',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          'Nếu giảm 20% chi tiêu ăn uống ngoài, bạn có thể đạt mục tiêu "Mua nhà" sớm hơn 6 tháng.',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85), height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  ...goals.asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value;
                    final pct = (g['current'] / g['target']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(children: [
                            Text(g['icon'], style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(g['name'])),
                            Text('${(pct * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: primaryColor)),
                          ]),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: pct,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showDepositDialog(i),
                            child: const Text('+ Nạp tiền',
                                style: TextStyle(color: primaryColor)),
                          ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _showAddGoalDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm mục tiêu mới'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}