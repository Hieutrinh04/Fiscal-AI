import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';

import 'home/home_screen.dart';
import 'wallet/wallet_screen.dart';
import 'statistic/statistic_screen.dart';
import 'setting/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      HomeScreen(onNavigate: (index) {
        setState(() => currentIndex = index);
      }),
      const WalletScreen(),
      const StatisticsScreen(),
      const SettingScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ================= BODY =================
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),

      /// ================= FAB =================
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: const Color(0xff2F80ED),
        onPressed: () {
          Navigator.pushNamed(context, '/add-transaction');
        },
        child: const Icon(
          Iconsax.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      /// ================= BOTTOM BAR =================
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _navItem(0, Iconsax.home, context.l10n.navHome),
              _navItem(1, Iconsax.wallet, context.l10n.navWallet),

              const SizedBox(width: 40),

              _navItem(2, Iconsax.chart, context.l10n.navStatistics),
              _navItem(3, Iconsax.setting, context.l10n.navSettings),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= NAV ITEM =================
  Widget _navItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    final isDark = context.read<SettingsProvider>().darkModeEnabled;
    final inactiveColor = isDark ? Colors.grey[500]! : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (currentIndex == index) return;
          setState(() {
            currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? const Color(0xff2F80ED) : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? const Color(0xff2F80ED) : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}