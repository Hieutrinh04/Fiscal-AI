import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int selectedTab = 0;

  /// 🔥 MOCK DATA
  final Map<String, dynamic> data = {
    "week": {
      "total": "đ1.5M",
      "chart": [58.0, 21.0, 14.0, 8.0],
      "ai": "Tuần này bạn chi 850K cho ăn uống (58%). Hãy thử nấu ăn tại nhà.",
    },
    "month": {
      "total": "đ5.2M",
      "chart": [40.0, 30.0, 20.0, 10.0],
      "ai": "Tháng này chi tiêu tăng 20%, hãy kiểm soát chi tiêu ăn uống.",
    },
    "year": {
      "total": "đ60M",
      "chart": [35.0, 25.0, 25.0, 15.0],
      "ai": "Năm nay bạn quản lý chi tiêu khá tốt, tiếp tục duy trì.",
    },
  };

  String get currentKey {
    switch (selectedTab) {
      case 0:
        return "week";
      case 1:
        return "month";
      case 2:
        return "year";
      default:
        return "week";
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = data[currentKey]["chart"];

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildTotalExpense(),
              _buildPieChart(chartData),
              _buildAiSuggestion(),
              _buildTrend(),
              _buildCategoryList(),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Thống kê",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _tabItem("Tuần", 0),
                _tabItem("Tháng", 1),
                _tabItem("Năm", 2),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _tabItem(String title, int index) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= TOTAL =================
  Widget _buildTotalExpense() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text("Tổng chi: ",
              style: TextStyle(color: Colors.grey)),
          Text(
            data[currentKey]["total"],
            style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// ================= PIE CHART =================
  Widget _buildPieChart(List chartData) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          sections: [
            PieChartSectionData(
              value: chartData[0],
              color: Colors.red,
              title: "${chartData[0]}%",
            ),
            PieChartSectionData(
              value: chartData[1],
              color: Colors.blue,
              title: "${chartData[1]}%",
            ),
            PieChartSectionData(
              value: chartData[2],
              color: Colors.grey,
              title: "${chartData[2]}%",
            ),
            PieChartSectionData(
              value: chartData[3],
              color: Colors.orange,
              title: "${chartData[3]}%",
            ),
          ],
        ),
      ),
    );
  }

  /// ================= AI =================
  Widget _buildAiSuggestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2F80ED), Color(0xff56CCF2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        data[currentKey]["ai"],
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// ================= TREND =================
  Widget _buildTrend() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildBar("T2", 0.7, "1.2M"),
        _buildBar("T3", 0.9, "1.5M"),
      ],
    );
  }

  Widget _buildBar(String day, double value, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(day)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(amount),
        ],
      ),
    );
  }

  /// ================= CATEGORY =================
  Widget _buildCategoryList() {
    return Column(
      children: const [
        SizedBox(height: 10),
        _categoryItem("Ăn uống", "850.000", Colors.red),
        _categoryItem("Di chuyển", "300.000", Colors.blue),
        _categoryItem("Khác", "200.000", Colors.grey),
        _categoryItem("Cafe", "110.000", Colors.orange),
      ],
    );
  }
}

class _categoryItem extends StatelessWidget {
  final String name;
  final String amount;
  final Color color;

  const _categoryItem(this.name, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        radius: 6,
      ),
      title: Text(name),
      trailing: Text("đ$amount"),
    );
  }
}